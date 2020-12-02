#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2019-11-27,14.59.56z/4646335>
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
needs add-exit-action amuse:env fpop play-one-ogg SQL

amuse:env	# Sets AMUSE_COMMANDS, AMUSE_RUN_DIR, AMUSE_DATA_HOME, and
			# creates function is-valid-amuse-cmd

CONTINUE=true
function kill-player { #{{{1
	[[ -s player-pid ]]|| return
	kill -HUP $(<player-pid) # -pid sends to group, including watch-file
	wait $FN_PLAY_PID
} #}}}1
function sig		{ >sigpipe print -- "$1" &	}
function hQuit		{ CONTINUE=false;			}
function hCleanUp	{ #{{{1
	rm -f sigpipe
	kill-player
	: >final
	: >server-pid
} #}}}1
function file-from-id { # {{{1
	local F P
	SQL "SELECT pcm_sha384b FROM files WHERE id = $1;"
	F="${sqlreply[0]#?}"
	P="${sqlreply[0]%"$F"}"
	REPLY="$AMUSE_DATA_HOME/$P/$F.oga"
} # }}}1
function move-played-to-history {
	local PlayedBuf PlayingBuf
	PlayingBuf="$(<playing)"
	: >playing
	PlayedBuf="$(<played.lst)"
	print -r -- "$PlayingBuf" >played.lst
	print -r -- "$PlayedBuf" >>played.lst
}
function play-file { # {{{1
	local action=played PlayedBuf PlayingBuf
	print -- 0 >timeplayed
	play-one-ogg "$1" ${2:-} >paused-at 3>timeplayed &
	print $! >player-pid
	wait $! || action=paused
	: >player-pid
	[[ -s again || -s paused-at ]]||
		move-played-to-history
	print $action >sigpipe
} # }}}1
function play-one-song { #{{{1
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
		# we're kind of done
		m
	else
		# Grab the song from the list
		fpop song.lst >playing || return 1
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
} #}}}1
function docmd-final { #{{{1
	print true >final
	return 1
} #}}}1
function docmd-pause { #{{{1
	kill-player
	return 1
} #}}}1
function docmd-play { #{{{1
	return 0
} #}}}1
function docmd-restart { #{{{1
	docmd-again
	docmd-skip
	return 0
} #}}}1
function docmd-stop { #{{{1
	kill-player
	: >paused-at
	move-played-to-history
	return 1
} #}}}1
function docmd-skip { #{{{1
	docmd-stop
	return 0
} #}}}1
function docmd-played { #{{{1
	return 0
	[[ -s final ]]&& {
		: >final
		return 1
	  }
} #}}}1
function docmd-paused { #{{{1
	return 1
} #}}}1
function startup { #{{{1
	[[ -s paused-at ]]&& return 1
	return 0
} #}}}1
function is-valid-cmd { # {{{1
	[[ $1 == @(played|paused) ]] || is-valid-amuse-cmd "$1"
} # }}}1
function handle-cmd { # {{{1
	typeset -l cmd="${1:-}"
	is-valid-cmd "${cmd-EMPTY}" || {
		if [[ -z $cmd ]]; then
			print 'Missing command from ^Ssigpipe^s.'
		elif [[ $cmd == no-op ]]; then
			: # nothing to see here, move along.
		else
			print 'Bad command: ^T$cmd^t from ^Ssigpipe^s.'
		fi
		return
	  }

	# if we're NOT PLAYING, ignore all commands EXCEPT play
	[[ -s playing && ! -s paused-at ]] ||
		[[ $cmd == play ]]|| return

	docmd-$cmd && {
		[[ -s ui-pid ]]&& kill -USR1 -$(<ui-pid)
		play-one-song
	  }
	[[ -s ui-pid ]]&& kill -USR1 -$(<ui-pid)
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

# do everything in the AMUSE RUN DIRECTORY
builtin cd "${AMUSE_RUN_DIR:?}" ||
	fullstop 'Could not `cd` to "$AMUSE_RUN_DIR".'
[[ -a sigpipe ]]&& fullstop 'Server already running.'

mkfifo sigpipe || fullstop 'Is server already running?'
print -- $$ >server-pid

SQLSEP='	'
SQL "ATTACH '$AMUSE_DATA_HOME/amuse.db3' AS amuse;"

trap hQuit		TERM QUIT
trap ''			HUP INT TSTP USR1 USR2
add-exit-action hCleanUp

#_________________________________________________________________________
sig no-op		# prime the fifo so it is opened (no fatal error
				# bypassing SIGEXIT) and give the loop something to do
				# at startup.
#_________________________________________________________________________
evloop;exit	# do the loop and exit on the same line so edits
						# to this file while running don't result in
						# weirdness

# Copyright (C) 2019 by Tom Davis <tom@greyshirt.net>.
