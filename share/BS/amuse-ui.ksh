#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2019-12-03,21.31.29z/287b41f>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

TAB='	'
CONTINUE=true
UpdateAll=false;
# Colors
colorBG='48;5;31'
colorPlayed="\\033[0;$colorBG;38;5;249m"
colorPlaying='\033[0;48;5;229;30m'
colorNext="\\033[0;$colorBG;30m"
colorStatus='\033[0;1;38;5;226;48;5;246m'
colorTPlayed='\033[38;5;22m'
colorTDSong='\033[38;5;18m'
colorTRemaining='\033[38;5;254m'
# Playing States
sPlaying='▶▶'
sRandom='▶☈'
#sRandom='▶🎲'
sStopped='▆▆'
sPaused='❚❚'
sFinal='▶▍'
sFinalPaused='❚▶▍'
# Additional status states
sAgain='🔂'
statusBarSize=all
DHMS='00:00'
DSEC=0

NEED_GET_SIZE=true

# Subscripts
SubScript[0]='₀'
SubScript[1]='₁'
SubScript[2]='₂'
SubScript[3]='₃'
SubScript[4]='₄'
SubScript[5]='₅'
SubScript[6]='₆'
SubScript[7]='₇'
SubScript[8]='₈'
SubScript[9]='₉'

# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         test amuse style screen stuff
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
function get-size { #{{{1
	NEED_GET_SIZE=false # we're getting it
	eval "$(resize -u)"
	lastRowPLAYED=$(((LINES-2)/4))
	rowPLAYING=$((lastRowPLAYED+1))
	rowSTATUS=$LINES
	if   ((COLUMNS > 33)); then	statusBarSize=all		# full size
	elif ((COLUMNS > 25)); then	statusBarSize=noplayed	# no total time
	elif ((COLUMNS > 14)); then	statusBarSize=remaining	# only remaining time
	elif ((COLUMNS > 11)); then statusBarSize=notime	# no time info
	else						statusBarSize=none		# no status info
	fi
	# SIZES with spaces: status=4, again=7 (max)
	#       TIME(played / total -> remaining)=22
	#       TIME(total -> remaining)=14
	#       TIME(remaining)=5
	case $statusBarSize in
		none)	colState=0;                   colTime=0;					;;
		notime)	colState=$(((COLUMNS-11)/2)); colTime=0;					;;
		*)		colState=$(((COLUMNS-22)/4)); colTime=$(((2*colState)+11));	;;
	esac
} #}}}1
function print-played { # {{{1
	print -n -- $colorTPlayed
	s2hms $1
} # }}}1
function print-dsong { # {{{1
	print -n -- "$colorTDSong$DHMS"
} # }}}1
function print-remaining { # {{{1
	print -n -- "$colorTRemaining"
	s2hms $((DSEC-$1))
} # }}}1
function update-time-all { # {{{1
	print-played $1
	print -n -- '\033[39m / '
	print-dsong
	print -n -- '\033[39m -> '
	print-remaining $1
} # }}}1
function update-time-noplayed { # {{{1
	print-dsong
	print -n -- '\033[39m -> '
	print-remaining $1
} # }}}1
function update-time-remaining { # {{{1
	print-remaining $1
} # }}}1
function update-time-notime { :; }
function update-time-none { :; }
function update-time { # {{{1
	local O=0 P p t

	[[ -s playing ]] || return

	print -n -- "\033[${colTime}G$colorStatus\033[22m"

	P=$(<timeplayed)
	P=${P%?}	# remove tenths
	P=${P:-0}	# necessary for when less than 1 second was played

	((P==LASTTIME))&& return

	LASTTIME=$P
	update-time-$statusBarSize $P # remove tenths of a second
} # }}}1
function update-status { # {{{1
	local status

	print -n -- "\033[$rowSTATUS;1H$colorStatus\033[2K"
	[[ $statusBarSize == none ]]&& return

	if [[ -s final ]]; then
		status=$sFinal
		[[ -s paused-at ]]&& status=$sFinalPaused
	elif [[ -s paused-at ]]; then
		status=$sPaused
	elif [[ -s playing ]]; then
		if [[ -s random ]]; then
			status=$sRandom
		else
			status=$sPlaying
		fi
	else
		status=$sStopped
	fi

	[[ -s again ]]&& {
		a=$(<again)
		if ((a>99)); then
			C='₉₉+'
		elif ((a>9)); then
			C=${SubScript[a/10]}${SubScript[a%10]}
		else
			C=${SubScript[a]}
		fi
		status="$status $sAgain$C"
	  }

	print -n -- "\033[${rowSTATUS};${colState}H${colorStatus}$status"
	LASTTIME=-1
	update-time
} # }}}1
function update-screen { # {{{1
#PS4='${0##*/}|$LINENO| '
	print -u2 -- " ==========================="
	print -u2 -- "   NEED_GET_SIZE(B): $NEED_GET_SIZE"
	$NEED_GET_SIZE && get-size
	print -u2 -- "   NEED_GET_SIZE(A): $NEED_GET_SIZE"
	print -u2 -- "              LINES: $LINES"
	print -u2 -- "            COLUMNS: $COLUMNS"
	print -u2 -- "      lastRowPLAYED: $lastRowPLAYED"
	print -u2 -- "         rowPLAYING: $rowPLAYING"
	print -u2 -- "          rowSTATUS: $rowSTATUS"

	local i id song dtenths
	i=$lastRowPLAYED
	while ((i)); do
		((i--))
		IFS=$TAB read -r id song dtenths || song=''
		BUFFER[i]="$song"
	done <played.lst
	IFS=$TAB read -r id song DURATION <playing
	DSEC=${DURATION%?}
	DHMS=$(s2hms ${DSEC:-0})
	BUFFER[rowPLAYING-1]="$song"
	i=$((rowPLAYING-1))
	while ((++i<LINES)); do
		IFS=$TAB read -r id song dtenths || song=''
		BUFFER[i]="$song"
	done <song.lst

	typeset -L$((COLUMNS-2)) L
	typeset status
	print -n -- "$colorPlayed"
	i=0
	while ((i<$lastRowPLAYED)); do
		L=${BUFFER[i]:-\~}
		((i++))
		print -n -- "\033[$i;1H $L "
	done
	L=${BUFFER[i]:-\~}
	((i++))
	print -n -- "\033[$i;1H $colorPlaying$L$colorNext "
	while ((i<(LINES-1))); do
		L=${BUFFER[i]:-\~}
		((i++))
		print -n -- "\033[$i;1H $L "
	done
	update-status
} # }}}1
function main-loop { #{{{1
	set-alternate-screen
	update-screen
	while $CONTINUE; do
		if $UpdateAll || ((DURATION==0)); then
			update-screen
		else
			update-time
		fi
		jobs -p %sleep >/dev/null 2>&1 || { sleep 999 & }
		wait %sleep
	done
	kill -TERM %sleep  >/dev/null 2>&1
} #}}}1
function CleanUp	{ # {{{1
	unset-alternate-screen
	rm subs-playing/$$
	rm subs-time/$$
} # }}}1
function hTerm		{ CONTINUE=false;						}
function hWinch		{ NEED_GET_SIZE=true; UpdateAll=true;	}
function hUpdate	{ UpdateAll=true;						}
function hTimer		{ UpdateAll=false;						}

needs amuse:env needs-cd
amuse:env

trap hTerm		INT HUP TERM QUIT
trap hWinch		WINCH
trap hUpdate	USR1
trap hTimer		USR2
trap CleanUp	EXIT

needs-cd -or-die "${AMUSE_RUN_DIR:?}"
# Set the titlebar text
print -nu2 "\033]0;$this_pgm\007"
# register the signals we want for changes to
print USR1 >subs-playing/$$		# general status
print USR2 >subs-time/$$		# time played

#PS4='${0##*/}/$LINENO: '
exec 2>~/log/${this_pgm%.ksh}.log

main-loop; exit

# Copyright (C) 2019 by Tom Davis <tom@greyshirt.net>.
