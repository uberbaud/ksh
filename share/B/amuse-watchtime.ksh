#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2020-09-15,05.47.11z/5901eae>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Sends USR2 signals on changes to $AMUSE_RUN_DIR/timeplayed.
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
		h)	usage;												;;
		\?)	die "Invalid option: ^B-$OPTARG^b.";				;;
		\:)	die "Option ^B-$OPTARG^b requires an argument.";	;;
		*)	bad_programmer "$Option";							;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
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

function hSig		{ kill $WATCH_PID; }
function hCleanUp	{ : >watchtime-pid;		}
needs amuse:env watch-file
amuse:env
cd ${AMUSE_RUN_DIR:?}
print -- $$ >watchtime-pid

trap hSig HUP INT TSTP TERM QUIT
add-exit-action hCleanUp

# wrap script guts in a function so edits to this script file don't 
# affect running instances of the script.
function main {
	while :; do
		[[ -s ui-pid ]]&&
			kill -USR2 $(<ui-pid)
		watch-file timeplayed &
		WATCH_PID=$!
		wait $WATCH_PID || break
	done
}

main "$@"; exit

# Copyright (C) 2020 by Tom Davis <tom@greyshirt.net>.
