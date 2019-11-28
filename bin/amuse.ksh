#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2019-11-27,01.39.24z/1cf87bd>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

player='/home/tw/work/clients/me/util/amuse/prac/obj/sio-ogg-player'
AMUSE_DATA_HOME="${XDG_DATA_HOME?}/amuse"
AMUSE_DB="$AMUSE_DATA_HOME/amuse.db3"
AMUSE_RUN="${XDG_DATA_HOME?}/run/amuse"

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Audio Controller
	           ^GSee Also:^g ^Thelp ^Uamuse^u^t
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

(($#))&& die 'Unexpected arguments. None expected.'
[[ -s amuse-pid ]]&&
	die "Currently running ^Bamuse^b? (pid $(<amuse-pid))"

needs $player SQL watch-file fpop

builtin cd "$AMUSE_RUN" || die 'Could not ^Tcd^t to ^S$AMUSE_RUN^s.'
SQL "ATTACH '$AMUSE_DATA_HOME/amuse.db3' AS amuse;"

CONTINUE=true

function file_from_id { # {{{1
	local F P
	SQL <<-==SQLITE==
		SELECT pcm_sha384b FROM files WHERE id = $1;
		==SQLITE==
	F="${sqlreply[0]#?}"
	P="${sqlreply[0]%"$F"}"
	REPLY="$AMUSE_DATA_HOME/$P/$F.oga"
} # }}}1
function play-file { # {{{1
	local action=play
	$player "$1" ${2:-} >paused-at &
	print $! >playsong-pid
	wait $! || action=pause
	: >playsong-pid
	[[ -s again || -s paused-at ]]||
		: >playing
	print $action >signal
} # }}}1
function play-one-song { # {{{1
	local startpos N song ACTION
	[[ $(<signal) == play ]]||	return 1
	[[ -s playsong-pid ]]&&		return 1

	if [[ -s playing && -s paused-at ]]; then
		startpos=$(<paused-at)
	elif [[ -s playing && -s again ]]; then
		N=$(<again)
		if ((--N)); then
			print -r -- $N>again
		else
			: >again
		fi
		startpos=
	else
		fpop >playing || return 1
		startpos=
	fi
	read REPLY song <playing
	file_from_id "$REPLY"
	notify "$song"
	play-file "$REPLY" $startpos &
	print 'play' >signal
	return 0
} # }}}1
function keep-playing { # {{{1
	$CONTINUE|| return 1
	[[ -s final ]]&& {
		: >final
		return 1
	  }
	[[ $(<signal) == @(quit|stop) ]]&& return 1
	return 0
} # }}}1
function quit { # {{{1
	CONTINUE=false
	print quit >signal
} # }}}1
function bye { # {{{1
	[[ -s playsong-pid ]]&&
		kill -HUP $(<playsong-pid)

	[[ -s again || -s paused-at ]]|| : >playing
	: >amuse-pid
	: >final
	: >signal
} # }}}1

print $$>amuse-pid

trap quit	HUP INT TERM
trap ''		TSTP CONT ALRM USR1 USR2
trap bye	EXIT

function loop {
	print play >signal

	while keep-playing; do
		play-one-song
		# do time consuming work here
		watch-file signal
	done
}

loop; exit


# Copyright (C) 2019 by Tom Davis <tom@greyshirt.net>.
