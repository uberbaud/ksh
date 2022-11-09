#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2022-10-26,02.43.47z/5e13a49>
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
	         Wait until a song ends.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
while getopts ':h' Option; do
	case $Option in
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
needs amuse:env subscribe unsubscribe-all

amuse:env || die "$REPLY"
needs-path -or-die "$AMUSE_RUN_DIR"

SUBSCRIPTIONS_FILES=
trap STILL_WAITING=false	USR1
trap unsubscribe-all		EXIT

subscribe $AMUSE_RUN_DIR/subs-playing USR1 ||
	die "Could not subscribe."

(($#))|| set -- :
STILL_WAITING=true
while $STILL_WAITING; do sleep 30 & wait; done; "$@"; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
