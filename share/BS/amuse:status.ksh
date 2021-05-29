#!/bin/ksh
# @(#)[:81Id-|HViZqX}StB;Fpu: 2017-11-11 08:16:41 Z tw@csongor]
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Show amuse information.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
function bad_programmer {	# {{{2
	die 'Programmer error:'	\
		"  No getopts action defined for [1m-$1[22m."
  };	# }}}2
while getopts ':h' Option; do
	case $Option in
		h)	usage;													;;
		\?)	die "Invalid option: [1m-$OPTARG[22m.";				;;
		\:)	die "Option [1m-$OPTARG[22m requires an argument.";	;;
		*)	bad_programmer "$Option";								;;
	esac
done
# remove already processed arguments
shift $(($OPTIND - 1))
# ready to process non '-' prefixed arguments
# /options }}}1
function warnOrDie { #{{{1
	case $warnOrDie in
		die)  die "$@" 'Use [1m-f22m to force an edit.';		;;
		warn) warn "$@";											;;
		*)    die '[1mProgrammer error[22m:' \
					'warnOrDie is [1m${warnOrDie}[22m.';		;;
	esac
} # }}}1
function is-empty { # {{{1
	[[ -s $1 ]]&& return 1
	print -- "  $2: \033[38;5;217m-\033[0m"
} # }}}1
function show-pipe { # {{{1
	print -- "  $2: \033[38;5;248m(\033[3mexists\033[23m)\033[0m"
} # }}}1
function show-file { # {{{1
	is-empty $1 "$2" && return
	print -- "  $2: \033[36m$(<$1)\033[0m"
} # }}}1
function show-list { # {{{1
	local text 
	is-empty $1 "$2" && return
	text=$(wc -l <$1)
	text=${text##+( )}
	print -- "  $2: \033[38;5;248m($text songs)\033[0m"
} # }}}1
function show-playing { # {{{1
	local dur id idlen info infolen mark
	is-empty $1 "$2" && return
	IFS='	' read -r -- id info dur <$1
	idlen=${#id}
	infolen=${#info}
	mark=' '
	((idlen+infolen>maxLen))&& mark='…'
	typeset -R$((maxLen-(idlen))) rtext=$info
	info="${rtext##+([ [:punct:]])}"
	print -- "  $2: \033[38;5;248m$id \033[38;5;217m$mark\033[34m$info\033[0m"
} # }}}1
function show-subdir { #{{{1
	local f=$1 fLeft=$2 s=s
	set -- $f/*
	[[ $1 == $f/\* ]]&& set --
	(($#==1))&& s=''
	print -- "  $fLeft: \033[1;36m$# \033[0;34msubscriber$s\033[0m"
} # }}}1
function show-extra { #{{{1
	local f=$1 fLeft=$2 fType
	set -- $(stat -f '%HT %T' "$f") ''
	fType=$1
	[[ $2 == \* ]]&& fType='Executable File'
	print -- "  $fLeft: \033[31mUNEXPECTED\033[0m $fType"
} # }}}1
function found { # {{{1
	typeset -i i=-1
	typeset -i x=${#expected[*]}
	while ((++i<x)); do
		[[ $1 == ${expected[i]} ]]|| continue
		unset expected[i]
		set -A expected -- "${expected[@]}"
		break
	done
} # }}}1

needs amuse:env
amuse:env || die "$REPLY"
builtin cd "$AMUSE_RUN_DIR" ||
	die "Could not ^Tcd^t to ^B$AMUSE_RUN_DIR^b."

set -- *
[[ $1 == \* ]]&& die "^S$AMUSE_RUN_DIR^s is ^Bempty^b."

integer X=0
for f { ((X<${#f}))&& X=${#f}; }
integer COLUMNS=$(tput cols)
integer maxLen=$((COLUMNS-(X+7)))
typeset -L$X fLeft

set -A expected --	audiodevice final paused-at played.lst player-pid	\
					playing random server-pid sigpipe song.lst 			\
					subs-playing subs-time timeplayed

for f; do
	fLeft=$f
	case $f in
		audiodevice)	show-file		$f "$fLeft";		;;
		final)			show-file		$f "$fLeft";		;;
		paused-at)		show-file		$f "$fLeft";		;;
		played.lst)		show-list		$f "$fLeft";		;;
		player-pid)		show-file		$f "$fLeft";		;;
		playing)		show-playing	$f "$fLeft";		;;
		random)			show-file		$f "$fLeft";		;;
		server-pid)		show-file		$f "$fLeft";		;;
		sigpipe)		show-pipe		$f "$fLeft";		;;
		song.lst)		show-list		$f "$fLeft";		;;
		subs-playing)	show-subdir		$f "$fLeft";		;;
		subs-time)		show-subdir		$f "$fLeft";		;;
		timeplayed)		show-file		$f "$fLeft";		;;
		*.core)			rm -f "$f";							;;
		*)				show-extra		$f "$fLeft";		;;
	esac
	found $f
done

[[ -n ${expected[*]:-} ]]&& {
	s=s
	n=${#expected[*]}
	((n==1))&& s=''
	warn "Missing $n file$s: ^B${expected[*]}^b"
  }

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
