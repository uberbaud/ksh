#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2022-06-30,01.19.55z/9c252f>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Reimplementation of D Window Manager command line controller
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
function list-simple-cmds { # {{{1
	local c
	set killclient quit setlayout togglebar togglefloating viewall zoom
	for c; do print $c; done
} # }}}1
function list-ui-cmds { # {{{1
	print view
} # }}}1
function list-i-cmds { # {{{1
	local c
	set focusmon focusstack incnmaster setlayoutex tagmon \
		tagex toggletagex viewex toggleviewex
	for c; do print $c; done
} # }}}1
function list-f-cmds { # {{{1
	print setmfact
} # }}}1
function list-all-cmds { # {{{1
	list-simple-cmds
	list-ui-cmds
	list-i-cmds
	list-f-cmds
} # }}}1
function list-cmds { # {{{1
	if [[ -t 1 ]]; then
		list-all-cmds | sort | column
	else
		list-all-cmds | sort
	fi
	exit 0
} # }}}1
# process -options {{{1
while getopts ':hl' Option; do
	case $Option in
		l)	list-cmds;														;;
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
function send-dwm-msg { xsetroot -name "fsignal:$*"; }
function simple-cmd { # {{{1
	local cmd=$1

	shift 1
	(($#))&& die "Too many arguments. None expected for command ^B$cmd^b"

	send-dwm-msg $cmd
} # }}}1
function cmd-w-args { # {{{1
	local cmd=$1 subcmd=$2 opt=$3

	shift 3
	(($#))&& die "Too many arguments. One expected for command ^B$cmd^b"

	send-dwm-msg $cmd $subcmd $opt

} # }}}1

(($#))|| die "Missing required argument ^Ucmd^u."
cmd=$1; shift

typeset -ft cmd-w-args
typeset -ft send-dwm-msg
set -x
case $cmd in
	killclient|quit|setlayout|toggle@(bar|floating)|viewall|zoom)
		simple-cmd $cmd "$@"
		;;
	view)
		dsktop=$1
		((dsktop >= 1 && dsktop <= 9))||
			die "^B$1^b is not a valid virtual desktop."
		((dsktop--))
		shift
		cmd-w-args $cmd ui $dsktop "$@"
		;;
	focus@(mon|stack)|incnmaster|setlayoutex|tagmon|?(toggle)@(tag|view)ex)
		cmd-w-args $cmd i "$@"
		;;
	setmfact)
		cmd-w-args $cmd f "$@"
		;;
	*)
		die "Unknown ^Ucommand^u."
		;;
esac; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
