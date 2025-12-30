#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2022-10-26,02.43.47z/5e13a49>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}
VERBOSE=false

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-v^t^] ^[^Ucount^u^]
	         Wait until ^Ucount^u number of songs end, then exit..
	           ^T-v^t  Verbose.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
while getopts ':hv' Option; do
	case $Option in
		v)	VERBOSE=true;													;;
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
function maybe-done { # {{{1
	# did we finish a song, or pause it
	[[ $SONG_IN_PROGRESS    != $(<$AMUSE_RUN_DIR/playing)
	|| $AGAIN               != $(<$AMUSE_RUN_DIR/again)
	|| $PAUSED_AT           != $(<$AMUSE_RUN_DIR/paused-at)
	]]&&  # if so, we're done
		STILL_WAITING=false
} # }}}1
function set-status-vars { # {{{1
	SONG_IN_PROGRESS=$(<$AMUSE_RUN_DIR/playing)
		[[ -n $SONG_IN_PROGRESS ]]|| {
			REPLY="no song is playing"
			return 1
		  }
	PAUSED_AT=$(<$AMUSE_RUN_DIR/paused-at)
		[[ -z $PAUSED_AT ]]|| {
			REPLY="player is paused"
			return 2
		  }
	AGAIN=$(<$AMUSE_RUN_DIR/again)
} # }}}1
function show-count { # {{{1
	local s=s
	((COUNT==1))&& s=
	notify "^B$c^b song$s to play."
} # }}}1
needs amuse:env subscribe unsubscribe-all

amuse:env || die "$REPLY"
needs-path -or-die "$AMUSE_RUN_DIR"

COUNT=${1:-1}
[[ $COUNT == *([0-9])[1-9] ]]||
	die '^IArg1^i ^(^Ucount^u^) must be a positive integer.'
typeset -i COUNT

set-status-vars || die "^BAMUSE^b: $REPLY"

SUBSCRIPTIONS_FILES=
trap maybe-done			USR1
trap unsubscribe-all	EXIT

subscribe $AMUSE_RUN_DIR/subs-playing USR1 ||
	die "Could not subscribe."

while :; do
	$VERBOSE && show-count
	STILL_WAITING=true
	while $STILL_WAITING; do sleep 30 & wait; done
	((--COUNT))&& break
	sleep 0.2
	set-status-vars || { warn "$REPLY"; break; }
done; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
