#!/bin/ksh
# <@(#)tag:tw.csongor.uberbaud.foo,2024-01-17,18.01.42z/4bbc549>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

realbin=$(realpath $(whence -p "$0"))
shortbin=${realbin##*/};	shortbin=${shortbin%.*}
REAL_NAME=$shortbin
CALLED_AS=${0##*/}

this_pgm=${0##*/}
function usage { # {{{1
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^Uapp-name^u^] ^Usub-command^u ^[^Uoptions^u ^S…]^s
	         Generalized sub-command manager/framework/coordinator.
	         If called as Something other than ^T$PGM^t, that will be
	         used as the ^Uapp-name^u.

	         Uses ^O$^o^VSUBCMDS_ALIASES^v, ^O$^o^VSUBCMDS_PREFIX^v, and will run the
	         function ^T_init^t if it exists and the above variables ^Bmay^b be
	         set therein.

	         ^O$^o^VSUBCMDS_ALIASES^v is a set of space separated aliases, each
	         of which is a ^Iflag^i or ^Iname^i, a colon ^(^T:^t^), and the name of
	         a function which will be called instead of the ^Iflag^i or ^Iname^i.

	         ^T_init^t will have the array ^Vargv^v defined with all parameters for
	         for ^T$PGM^t, and should process only those general parameters,
	         leaving the rest and removing the ones it uses.

	       ^T$PGM -h^t^|^Thelp^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}1
function mk-subcmds-list { # {{{1
	local c s p prefix sedpgm
	: ${APP_PATH:?}
	prefix=${SUBCMDS_PREFIX:-subcmd-}
	sedpgm="/^function $prefix/{s/^function //;s/[[:space:]].*//;p;}"
	set --												\
		"$@"											\
		${full_pgm:+$(sed -nEe "$sedpgm" "$full_pgm")}	\
		$(matching-commands "$prefix*")

	integer i=0
	p=
	for c; do
		[[ $c == _init ]]&& continue # _init is reserved
		s=${c#"$prefix"}; s=${s%.ksh}
		[[ $s == $p ]]&& continue
		CMD_LIST[i]=$s
		SUBCMDS_MAP[i++]="$s $c"
		p=$s
	done
	set -A CMD_LIST -s -- "${CMD_LIST[@]}"
} # }}}1
function is-subcmd-valid { # {{{1
	local c REPLY
	for c in "${CMD_LIST[@]}"; do
		[[ $1 == $c ]]&& return
	done
	false
} # }}}1
function sub-command-already-exists { # {{{1
	for fn in $SC_PREF$1{,.ksh}; do
		whence "$fn" >/dev/null && return
	done
	false
} # }}}1
function list-cmds { # {{{1
	local c
	for c in "${CMD_LIST[@]}"; do
		print -r -- "$c"
	done
} # }}}1
function process-subcmds-aliases { # {{{1
	local a fname body S
	S='^O$^o^VSUBCMDS_ALIASES^v:'
	for a in "$@" ${SUBCMDS_ALIASES:-}; do
		[[ $a == *:* ]]|| bad-programmer "SUBCMDS_ALIASES: ^V$a^v is not valid"
		fname=${a%%:*}
		sub-command-already-exists "$fname" &&
			bad-programmer "$S ^T$fname^t already exists."
		body=${a#"$fname":}
		whence "$body" >/dev/null ||
			bad-programmer \
				"$S function ^T$body^t does not exist." \
				"(aliased to ^T$fname^t)"
		eval "function $SC_PREF$fname { $body; }"
	done
} # }}}1
function show-help { # {{{1
	NOT-IMPLEMENTED
} # }}}1
function do-sub-command { # {{{1
	local cmd c

	if [[ $1 == help ]]; then
		c=show-help
	else
		for c in "$SC_PREF$1" "$SC_PREF$1.ksh"; do
			whence "$c" >/dev/null && break
		done
		[[ -n $c ]]|| die "Weirdly, $SC_PREF$1{,.ksh} don't exist."
	fi

	cmd=$c; shift
	$cmd "$@"
} # }}}1

needs use-app-paths desparkle sed

if [[ $CALLED_AS == $REAL_NAME ]]; then
	[[ ${1:-} == @(-h|--help|help) ]]&& usage
	(($#))||
		die '^Uapp-name^u not give as parameter nor by ^Balias^b^/^Blink^b.'
	APP=$1; shift
else
	APP=$CALLED_AS
fi

desparkle "$APP" dAPP
(($#))|| die "Missing ^Usub-command^u for ^V$dAPP^v."

use-app-paths -or-false -- "$APP" || bad-programmer						\
		"^V$dAPP^v is neither"											\
		"    the name of a valid sub-command wrapping application, nor"	\
		"    a valid option for $REAL_NAME."

x=$(whence _init) && {
	[[ $x == [\'/]* ]]&&
		bad-programmer '^T_init^t ^Bmust^b be but is not a function.'
	set -A argv -- "$@"
	_init
	((${argv[*]+1}))||
		die "Missing ^Usub-command^u for ^V$dAPP^v."
	set -- "${argv[@]}"
  }
SC_PREF=${SUBCMDS_PREFIX:-subcmd-}
process-subcmds-aliases

set -A CMD_LIST
set -A SUBCMDS_MAP
mk-subcmds-list help

subcmd=$1; shift
[[ $subcmd == @(-h|--help) ]]&& subcmd=help
is-subcmd-valid "$subcmd" || {
	desparkle "$subcmd"
	die "^B$REPLY^b is not a valid sub-command for ^B$dAPP^b."
  }

do-sub-command "$subcmd" "$@"; exit

# Copyright (C) 2024 by Tom Davis <tom@greyshirt.net>.
