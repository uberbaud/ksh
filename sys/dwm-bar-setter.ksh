#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2020-12-26,01.41.48z/5c8397f>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

: ${HOST:?}

# ===============================
#  GLOBAL CONSTANTS
# ===============================
readonly LOGDIR=~/log
readonly dSTATUS=${XDG_CACHE_HOME:?}/monitor-daemon-log
readonly dSUBSCRIBE=$dSTATUS/subscribers

# screen color per apm
readonly						\
	colorCrit='dark red'		\
	colorWarn='dark goldenrod'	\
	colorNormal=\#707070

readonly TAB='	'

# text color markers for dwm bar (dwm/config.h)
readonly					\
	cNrm=$(print '\001')	\
	cGry=$(print '\002')	\
	cSel=$(print '\003')	\
	cBlu=$(print '\004')	\
	cWrn=$(print '\005')	\
	cCrt=$(print '\006')	\
	cOK=$(print  '\007')	\
	cXXX=$(print '\010')	\
	cInv=$(print '\011')

# apm -b returns
readonly batHigh=0 batLow=1 batCrit=2 batChrg=3 batNone=4 batUnknown=255

# ===============================
#  GLOBAL VARIABLES
# ===============================
LastState=''
CONTINUE=true

PWR=''
NET=''
CPU=''
TIME=''
AMUSE_STATUS='';	ASTAT_NEEDS_UPDATING=true
REMAINING='';		RMNNG_NEEDS_UPDATING=true
DURATION=0

typeset -i10 T_MINUS=0

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Updates DWM's status bar with ^Isystem^i and ^Iamuse^i information.
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
function power-sitch-is-fine { #{{{1
	hsetroot -solid "$colorNormal"
} # }}}1
function battery-is-low { #{{{1
	hsetroot -solid "$colorWarn"
} #}}}1
function battery-is-critical { #{{{1
	hsetroot -solid "$colorCrit"
	[[ -n ${1:-} ]]|| return
	date +"$ISO_DATE: $*"
	apm
	$KDOTDIR/share/BS/lockdown.ksh Z # hibernate to disk
} #}}}1
function update-apm-info { #{{{1
	local state cState pluggedin BAT PERC MIN
	pluggedin=false
	# apm returns: BATTERY PERCENTAGE MINUTES A/C  in that order
	set -- $(/usr/sbin/apm -blma)
	BAT=$1; PERC=$2; MIN=$3; AC=$4

	# A/C STATUS: 0=disconnected, 1=connected, 2=backup source, 255=???
	# BATTERY: 0=high, 1=low, 2=critical, 3=charging, 4=absent, 255=???
	case $BAT in
		$batHigh)	state=cOK;			;;
		$batLow)	state=cOK;			;;
		$batCrit)	state=cCrt
			if (($PERC<=2 || $MIN<10)); then		# LE 2% or LT 10 minutes
				((AC))|| battery-is-critical SHUT IT DOWN
			elif (($PERC<=7 || $MIN<30)); then	# LE 7% or LT 30 minutes
				((AC))|| battery-is-critical
			elif (($PERC<=15 || $MIN<60)); then	# LE 5% or LT 60 minutes
				((AC))|| battery-is-low
				state=cWrn
			else							# otherwise
				state=cOK
			fi
			;;
		# NOTE: batChrg != connected to AC
		$batChrg)	state=cOK;			;;
		#$batNone)	state=cWrn;			;;
		*)			state=cNrm;			;;
	esac
	[[ $state != $LastState ]]&& {
		LastState=$state
		[[ $state == @(cOK|cNrm) || AC -eq 1 ]]&&
			power-sitch-is-fine
	  }
	eval cState="\$$state"
	# PERCENTAGE
	PWR="$cState$PERC% "
	if [[ $MIN == +([0-9]) ]]; then
		typeset -i h=0 m=$MIN
		((m>59))&& {
			h=$((m/60))
			m=$((m%60))
			typeset -Z2 -i m
			PWR="$PWR$h${cNrm}h$cState"
		  }
		PWR="$PWR$m${cNrm}m$cState "
	else
		PWR=$PWR${cOK}AC
	fi
} #}}}1
function update-cpu-info { #{{{1
	CPU=$(sysctl -n hw.cpuspeed)
	case $CPU in
		500)	CPU="${cInv}0$cOK$CPU";		;;
		???)	CPU="${cInv}0$cNrm$CPU";	;;
		2???)	CPU="$cCrt$CPU";			;;
		*)		CPU="$cNrm$CPU";			;;
	esac
} #}}}1
function update-net-info { #{{{1
	[[ -f $dSTATUS/network ]]&&
		NET=$(<$dSTATUS/network)
} #}}}1
function update-time-info { #{{{1
	set -- $(date +'%S %b %e %k:%M')
	typeset -i10 seconds=${1#0}	# remove leading 0 which otherwise reps octal
	((T_MINUS=60-seconds)); shift
	TIME=$*

} #}}}1
function update-amuse-status { #{{{1
	local id songinfo dtenths
	AMUSE_STATUS=''
	DURATION=0
	[[ -s playing ]]&& {
		IFS="$TAB" read -r id songinfo dtenths <playing
		DURATION=${dtenths%?}
		AMUSE_STATUS="$cBlu${songinfo##*\|}"
	  }
	ASTAT_NEEDS_UPDATING=false
	RMNNG_NEEDS_UPDATING=true
} #}}}1
function update-amuse-remaining { #{{{1
	local ptenths remaining
	REMAINING=''
	((DURATION))&& {
		ptenths=$(<timeplayed)
		played=${ptenths%?}
		REMAINING=$(s2hms $((DURATION-played)))
		# do some spacing here
		if [[ $REMAINING == 0* ]]; then
			REMAINING="${cInv}M0$cNrm${REMAINING#0}${cInv}MM"
		else
			REMAINING="${cInv}M$cNrm$REMAINING${cInv}MM"
		fi
	  }
	RMNNG_NEEDS_UPDATING=false
} #}}}1
function loop { # {{{1
	local I
	while $CONTINUE; do
		update-apm-info
		update-cpu-info
		update-net-info
		update-time-info
		$ASTAT_NEEDS_UPDATING && update-amuse-status
		$RMNNG_NEEDS_UPDATING && update-amuse-remaining
		I="$AMUSE_STATUS $REMAINING $CPU$cNrm $NET $PWR$cNrm  $TIME "
		xsetroot -name "$I"
		jobs -p %sleep >/dev/null 2>&1 || { sleep  $T_MINUS & }
		wait %sleep # allows for signal processing
	done
} # }}}1

needs hsetroot amuse:env needs-path s2hms subscribe unsubscribe-all xsetroot

(($#))&& die 'Too many arguments. Did not expect any.'

needs-path -or-die "$LOGDIR"
exec >$LOGDIR/${this_pgm%%.*}.log 2>&1

LOCKNAME=dwm-bar-setter
get-exclusive-lock -no-wait "$LOCKNAME" ||
	die 'Another dwm-bar-setter is already running.' 'Exiting.'

amuse:env || die "$REPLY"
needs-cd -or-die "$AMUSE_RUN_DIR"

SUSCRIPTION_FILES=
subscribe $dSUBSCRIBE	INFO
subscribe subs-playing	USR1
subscribe subs-time		USR2

trap unsubscribe-all			EXIT
trap 'CONTINUE=false'			INT QUIT ALRM TERM
trap ''							TSTP
trap :							HUP INFO
trap ASTAT_NEEDS_UPDATING=true	USR1
trap RMNNG_NEEDS_UPDATING=true	USR2

loop "$@"; exit 0

# Copyright (C) 2020 by Tom Davis <tom@greyshirt.net>.
