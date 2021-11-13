#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2019-11-27,14.59.56z/4646335>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}
typeset -R5 LINENO
PS4='$LINENO | '

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         ^IAmuse^i server.
	           Accepts commands:
	             ^I$CMDLIST^i
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
function bad_programmer {	# {{{2
	fullstop 'Programmer error:'	\
		"  No getopts action defined for [1m-$1[22m."
  };	# }}}2
while getopts ':h' Option; do
	case $Option in
		h)	usage;													;;
		\?)	fullstop "Invalid option: -$OPTARG.";					;;
		\:)	fullstop "Option -$OPTARG requires an argument.";		;;
		*)	bad_programmer "$Option";								;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
needs amuse:env get-exclusive-lock fpop play-one-ogg release-exclusive-lock SQL
# Set AMUSE_COMMANDS, AMUSE_RUN_DIR, AMUSE_DATA_HOME, and
# create function is-valid-amuse-cmd
amuse:env || fullstop "$REPLY"
: ${AMUSE_DATA_HOME:?} ${AMUSE_RUN_DIR:?}

alias please-START-another-song='return 0'
alias DONT-start-another-song='return 1'

SERVER_LOCK=
CONTINUE=true
function kill-player { #{{{1
	[[ -s player-pid ]]|| return
	kill -HUP $(<player-pid) # -pid sends to group
	wait $FN_PLAY_PID
	: >final	# final, we're stopping immediately, not finishing
				# the song, which is the purpose of final
} #}}}1
function sig		{ >sigpipe print -- "$1" &	}
function hQuit		{ CONTINUE=false;			}
function hCleanUp	{ #{{{1
	release-exclusive-lock "$SERVER_LOCK"
	rm -f sigpipe
	kill-player
	: >final
	: >server-pid
	: >player-pid
} #}}}1
function file-from-id { # {{{1
	local F P
	SQL "SELECT pcm_sha384b FROM files WHERE id = $1;"
	F="${sqlreply[0]#?}"
	P="${sqlreply[0]%"$F"}"
	REPLY="$AMUSE_DATA_HOME/$P/$F.oga"
} # }}}1
function move-played-to-history { # {{{
	local PlayedBuf PlayingBuf
	PlayingBuf="$(<playing)"
	: >playing
	PlayedBuf="$(<played.lst)"
	print -r -- "$PlayingBuf" >played.lst
	print -r -- "$PlayedBuf" >>played.lst
} # }}}
function play-file { # {{{1
	local action=played PlayedBuf PlayingBuf
	print -- 0 >timeplayed
	#======================================[ heavy lifter ]===============#
	AUDIODEVICE=${vAUDEV:-snd/0} play-one-ogg "$1" ${2:-}	\
		1>paused-at											\
		2>~/log/amuse-player.log							\
		3>timeplayed										\
		&
	#=====================================================================#
	print $! >player-pid
	wait $! || action=paused
	: >player-pid
	[[ -s again || -s paused-at ]]||
		move-played-to-history
	print $action >sigpipe
} # }}}1
function get-random-song  { #{{{1
	local song id
	[[ -s random ]]|| return 1
	SQL <<-==SQLITE==
		SELECT
			id,
			performer || '|' || album || '|' || track || '|' || song,
			dtenths
		  FROM vsongs
		 WHERE id IN (
	 		SELECT id
			  FROM amuse.files
			 ORDER BY random()
			 LIMIT 1
			)
		;
	==SQLITE==
	(($?))&& return 1			# would be Programmer's Fault, never expected
	song=${sqlreply[0]:-}
	[[ -n $song ]]|| return 1	# should never happen, but just in case.
	print -r -- "$song"
} #}}}1
function play-next-song { #{{{1
	local N amuse_id song startpos
	[[ -s player-pid ]]&& return 1

	# keep or put next song in playing
	if [[ -s playing && -s paused-at ]]; then
		# song was paused
		startpos=$(<paused-at)
	elif [[ -s playing && -s again ]]; then
		N=$(<again)
		if ((--N)); then
			print -r -- $N >again
		else
			: >again
		fi
		startpos=
	elif [[ -s final && -s again ]]; then
		# we don't want to continue, but we need to do some clean up
		:
	elif [[ -s final ]]; then
		: # we're kind of done
	else
		# Grab the song from the list
		{ fpop song.lst || get-random-song; } >playing || return 1
		startpos=
	fi
	read amuse_id the_rest <playing
	file-from-id "$amuse_id"
	play-file "$REPLY" $startpos &
	FN_PLAY_PID=$!

	return 0
} #}}}1
function docmd-again { #{{{1
	local N=0
	[[ -s again ]]&& N=$(<again)
	print $((N+1)) >again
	# we're MARKING it for replay, but we're in the middle of playing
	# the song, so don't RESTART it.
	DONT-start-another-song
} #}}}1
function docmd-final { #{{{1
	print true >final
	DONT-start-another-song
} #}}}1
function docmd-pause { #{{{1
	kill-player
	# don't restart THIS song
	DONT-start-another-song
} #}}}1
function docmd-play { #{{{1
	: >final
	[[ -s player-pid && -z $(ps -p $(<player-pid) -ocommand=) ]]&&
		: >player-pid
	please-START-another-song
} #}}}1
function stop-song { #{{{1
	kill-player
	: >paused-at
} #}}}1
function docmd-restart { #{{{1
	docmd-again
	stop-song
	please-START-another-song
} #}}}1
function docmd-stop { #{{{1
	stop-song
	move-played-to-history
	DONT-start-another-song
} #}}}1
function docmd-skip { #{{{1
	docmd-stop
	please-START-another-song
} #}}}1
function docmd-played { #{{{1
	[[ -s final ]]&& {
		: >final
		DONT-start-another-song
	  }

	please-START-another-song
} #}}}1
function docmd-paused { #{{{1
	DONT-start-another-song
} #}}}1
function docmd-no-op { #{{{1
	DONT-start-another-song
} #}}}1
function docmd-changed-audev { # {{{1
	vAUDEV=$(<audiodevice)
	DONT-start-another-song
} # }}}1
function is-valid-cmd { # {{{1
	[[ $1 == @(played|paused|no-op|changed-audev) ]] || is-valid-amuse-cmd "$1"
} # }}}1
function notify-subscribers { # {{{1
	local file pid signal subtype
	subtype=$1
	for file in subs-$subtype/+([0-9]); do
		[[ -f $file ]]|| continue
		pid=${file##*/}
		signal=$(<$file)
		kill -$signal $pid 2>/dev/null || rm $file
	done
} # }}}1
function handle-cmd { # {{{1
	local PLAYING
	typeset -l cmd="${1:-}"
	is-valid-cmd "${cmd-EMPTY}" || {
		if [[ -z $cmd ]]; then
			print 'Missing command from ^Ssigpipe^s.'
		else
			print "Bad command: ^T$cmd^t from ^Ssigpipe^s."
		fi
		return
	  }

	if [[ -s paused-at ]]; then
		PLAYING=false
	elif [[ -s playing ]]; then
		PLAYING=true
	else
		PLAYING=false
	fi

	# IF we're NOT PLAYING, ignore all commands EXCEPT play(ed)
	$PLAYING || [[ $cmd == play?(ed) ]]|| return

	docmd-$cmd && {
		notify-subscribers playing
		play-next-song
	  }
	notify-subscribers playing
} # }}}1
function evloop { # {{{1
	local cmd
	# Any time read is called on an empty fifo which had previously been
	# written to, it returns false, thus we need the outer while loop
	# and we need to re-open sigpipe once per while loop.
	# After that, `read` blocks until written to, so we're not looping
	# at 100% CPU here.
	while $CONTINUE; do
		while read -r cmd; do
			handle-cmd $cmd
		done <sigpipe
	done
	true
} # }}}1
# ----------8<-----[ BEGIN amuse-watchtime.ksh ]-----8<----------
function hwtSig		{ KEEP_WATCHING=false;  }
function watchtime	{ # {{{1
	trap hwtSig HUP INT TSTP TERM QUIT
	trap ''		USR1 USR2 WINCH

	KEEP_WATCHING=true;
	while $KEEP_WATCHING; do
		notify-subscribers time
		watch-file timeplayed &
		WATCH_PID=$!
		wait $WATCH_PID || break
	done
	kill $WATCH_PID 2>/dev/null;

} # }}}1
# ----------->8-----[ END amuse-watchtime.ksh ]----->8-----------

# do everything in the AMUSE RUN DIRECTORY
builtin cd "$AMUSE_RUN_DIR" ||
	fullstop 'Could not `cd` to "$AMUSE_RUN_DIR".'

get-exclusive-lock -no-wait server-lock "$AMUSE_RUN_DIR" ||
	fullstop 'amuse-server is already running'
SERVER_LOCK=$REPLY

[[ -s server-pid && -n $(ps -p $(<server-pid) -ocommand=) ]]&&
	fullstop 'amuse-server is already running (2)'
print -- $$ >server-pid

[[ -a sigpipe ]]&& rm -f sigpipe
mkfifo sigpipe || fullstop 'Is server already running?'

: >final
: >player-pid
touch random		# don't change it, just make sure it exists
touch audiodevice	# don't change it, just make sure it exists
vAUDEV=$(<audiodevice)

SQLSEP='	'
SQL "ATTACH '$AMUSE_DATA_HOME/amuse.db3' AS amuse;"

trap hQuit		TERM QUIT
trap ''			HUP INT TSTP USR1 USR2
trap hCleanUp	EXIT

watchtime >&2 &
#_________________________________________________________________________
sig no-op		# prime the fifo so it is opened (no fatal error
				# bypassing SIGEXIT) and give the loop something to do
				# at startup.
#_________________________________________________________________________
evloop;exit	# do the loop and exit on the same line so edits
						# to this file while running don't result in
						# weirdness

# Copyright (C) 2019 by Tom Davis <tom@greyshirt.net>.
