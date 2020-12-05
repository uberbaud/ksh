#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2019-12-03,21.31.29z/287b41f>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

TAB='	'
CONTINUE=true
UpdateAll=true;
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
sStopped='▆▆'
sPaused='❚❚'
sFinal='▶▍'
sFinalPaused='❚▶▍'
# Additional status states
sAgain='🔂'
statusBarSize=all
DHMS='00:00'
DSEC=0

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
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
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
	local x
	LINES=$(tput lines)
	COLUMNS=$(tput columns)
	lastRowPLAYED=$(((LINES-2)/4))
	rowPLAYING=$((lastRowPLAYED+1))
	rowSTATUS=$LINES
	# SIZES with spaces: status=4, again=7 (max)
	#       TIME(played / total -> remaining)=22
	#       TIME(total -> remaining)=14
	#       TIME(remaining)=5
	if ((COLUMNS > 33)); then
		# full size
		statusBarSize=all
		x=$(((COLUMNS-33)/4))
		colState=$x
		colTime=$((x+11+x))
	elif ((COLUMNS > 25)); then
		# no total time
		statusBarSize=noplayed
		x=$(((COLUMNS-22)/4))
		colState=$x
		colTime=$((x+11+x))
	elif ((COLUMNS > 14)); then
		# only remaining time
		statusBarSize=remaining
		x=$(((COLUMNS-22)/4))
		colState=$x
		colTime=$((x+11+x))
	elif ((COLUMNS > 11)); then
		# no time info
		statusBarSize=notime
		colState=$(((COLUMNS-11)/2))
		colTime=0
	else
		# no status info
		statusBarSize=none
		colState=0
		colTime=0
	fi
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
		status=$sPlaying
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
	local i id song dtenths
	i=$lastRowPLAYED
	while ((i)); do
		((i--))
		IFS="$TAB" read -r id song dtenths || song=''
		BUFFER[i]="$song"
	done <played.lst
	IFS="$TAB" read -r id song DURATION <playing
	DSEC=${DURATION%?}
	DHMS=$(s2hms ${DSEC:-0})
	BUFFER[rowPLAYING-1]="$song"
	i=$((rowPLAYING-1))
	while ((++i<LINES)); do
		IFS="$TAB" read -r id song dtenths || song=''
		BUFFER[i]="$song"
	done <song.lst

	typeset -L$((COLUMNS-2)) L
	typeset status
	print -n -- "$colorPlayed"
	i=0
	while ((i<$lastRowPLAYED)); do
		L="${BUFFER[i]:-~}"
		((i++))
		print -n -- "\033[$i;1H $L "
	done
	L="${BUFFER[i]:-~}"
	((i++))
	print -n -- "\033[$i;1H $colorPlaying$L$colorNext "
	while ((i<(LINES-1))); do
		L="${BUFFER[i]:-~}"
		((i++))
		print -n -- "\033[$i;1H $L "
	done
	update-status
} # }}}1
function main-loop { #{{{1
	#$KDOTDIR/bin/amuse-watchtime.ksh &
	get-size
	set-alternate-screen
	while $CONTINUE; do
		if $UpdateAll; then
			update-screen
		else
			update-time
		fi
		jobs -p %sleep >/dev/null 2>&1 || { sleep 999 & }
		wait %sleep
	done
	kill -TERM %sleep  >/dev/null 2>&1
} #}}}1
function CleanUp	{ unset-alternate-screen; : >ui-pid;	}
function hTerm		{ CONTINUE=false;						}
function hWinch		{ get-size;								}
function hUpdate	{ UpdateAll=true;						}
function hTimer		{ UpdateAll=false;						}
# ----------8<-----[ BEGIN amuse-watchtime.ksh ]-----8<----------
function hwtSig		{ KEEP_WATCHING=false; }
function watchtime	{ # {{{1
	trap hwtSig HUP INT TSTP TERM QUIT
	trap ''		USR1 USR2

	KEEP_WATCHING=true;
	while $KEEP_WATCHING; do
		[[ -s ui-pid ]]&& kill -USR2 $$
		watch-file timeplayed &
		WATCH_PID=$!
		wait $WATCH_PID || break
	done

} # }}}1
# ----------->8-----[ END amuse-watchtime.ksh ]----->8-----------

needs amuse:env watch-file
amuse:env

trap hTerm		INT HUP TERM QUIT
trap hWinch		WINCH
trap hUpdate	USR1
trap hTimer		USR2
trap CleanUp	EXIT

cd "${AMUSE_RUN_DIR:?}" || die 'Could not ^Tcd^t to ^S$AMUSE_RUN_DIR^s.'

>ui-pid print -- $$
main_shell_pid=$$

PS4='${0##*/}/$LINENO: '
exec 2>~/log/${this_pgm%.ksh}.log

watchtime >&2 &
main-loop; exit

# Copyright (C) 2019 by Tom Davis <tom@greyshirt.net>.
