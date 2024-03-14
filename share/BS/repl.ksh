#!/bin/ksh
# <@(#)tag:tw.csongor.uberbaud.foo,2024-03-06,03.11.13z/48a113b>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-r^t^] ^Ulanguage^u
	         A generalized Read Evaluate Print Loop framework for any ^Ulanguage^u.
	           ^T-r^t  Runs the extracted file rather than ^Tmake^t-ing it.
	         Extracts a file from the ^IREPL^i file, optionally builds an executable, and
	         runs it, in a loop on ^IREPL^i file change. Uses:
	             ^Tmake -f^t ^O\$^o^VXDG_CONFIG_HOME^v^T/repl/^t^Ulanguage^u^T.mk^t ^O\${^o^Vx^v^O%^o^T.^t^*^O}^o
	         and runs
	             ^O\${^o^VMAKEOBJDIR^v^O:-^o^Tobj^t^O}^o^T/^t^O\${^o^Vx^v^O%^o^T.^t^*^O}^o
	       ^T$PGM -h^t
	         Show this help message.

	       ^GNote: In the ^IREPL^i file, lines beginning with^g ^T==^t ^Gwill be stripped, and^g
	             ^Ga line consisting of^g ^T====^t ^G(exactly four equals signs), marks the^g
	             ^Gend of the extracted file. In the first block of comment lines, the^g
	             ^Gspecial lines^g
	                 ^T== Filename:^t ^Ufile.ext^u
	                 ^T== Language:^t ^Usyn_lang^u
	             ^Gwill be used to determine the extracted ^Ufilename^u and the neovim^g
	             ^Glanguage name for syntax highlighting. Lines beginning with^g
	                 ^T==|^t
	             ^Gwill be included in the ^IMakefile^i with that prefix stripped.^g
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
needs_build=true
while getopts ':rh' Option; do
	case $Option in
		r)	needs_build=false;												;;
		h)	usage;															;;
		\?)	die USAGE "Invalid option: ^B-$OPTARG^b.";						;;
		\:)	die USAGE "Option ^B-$OPTARG^b requires an argument.";			;;
		*)	bad-programmer "No getopts action defined for ^T-$Option^t.";	;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
function write-repl { # {{{1
	local bang
	typeset -l ext
	$needs_build || bang=$(/usr/bin/which $LANG 2>/dev/null)
	ext=$(awk "/^$LANG[[:space:]]/ {print \$2}" "$EXTS")
	[[ -n ext ]]|| ext=$LANG
	cat <<-...
		========================================================================
		== Filename: test_1.$ext
		== Language: $LANG
		========================================================================
		==|  # Makefile pass through
		========================================================================
		${bang:-}
		====
		Everything after the four equals is ignored.
		...
} # }}}1
function truthify { # {{{1
	[[ -n ${1:-} ]]|| die "truthify: Missing parameter 1: ^Uvarname^u"
	[[ $1 == [A-Za-z_]*([A-Za-z0-9_]) ]]||
		die "truthify: ^Uvarname^u parameter is not a valid variable name."
	if [[ $1 == maybe ]]; then
		typeset -l temp=$maybe
		maybe=$temp
	else
		typeset -l maybe
		eval maybe=\${$1:-false} # empty is false
	fi
	case $maybe in
		yes|true|on|1)	maybe=true;		;;
		no|false|off|0)	maybe=false;	;;
		*)
			desparkle "$maybe" maybe
			die '^O$^o^V'"$1 ^(^T$maybe^t^) is not a truthy value." \
				'truthy values: ^Tyes^t, ^Tno^t, ^Ttrue^t, ^Tfalse^t, ^Ton^t, ^Toff^t, ^T1^t, or ^T0^t.'
			;;
	esac
	[[ $1 == maybe ]]|| eval $1=$maybe
} # }}}1
function main { # {{{1
	[[ -s $REPL ]]||
		write-repl "$LANG" >$REPL
	WATCHID=REPL-$LANG-$(compact-timestamp -z)
	while watch-file -i "$WATCHID" -v $REPL; do
		NOT-IMPLEMENTED
	done
} #}}}1
(($#))|| die 'Missing required parameter: ^Ulanguage^u.'
(($#>1))&& die 'Too many parameters. Expected only one: ^Ulanguage^u.'

needs needs-file needs-path watch-file compact-timestamp

LANG=$1
REPL=repl.src
CFGDIR=${XDG_CONFIG_HOME:?}/repl
EXTS=$CFGDIR/extensions

needs-path -create -with-notice -or-die ./RCS
needs-path -or-die "$CFGDIR"
needs-file -or-die "$EXTS"
$needs_build && {
	needs-file -or-die "$CFGDIR/$LANG.mk"
	needs-path -create -with-notice -or-warn "${MAKEOBJDIR:-./obj}"
}

main "$@"; exit

# Copyright (C) 2024 by Tom Davis <tom@greyshirt.net>.
