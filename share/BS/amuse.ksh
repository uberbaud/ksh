#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2019-12-04,00.38.48z/38a1f07>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

ACCEPTCMD=true
ACTION=Start
AMUSE_SCRIPT_PATH=$KDOTDIR/csongor/B
SYSTEMS_ARE_GO=true
awk_status_pgm="$(</dev/stdin)" <<-\
	\===AWK===
	$2 == "/bin/ksh" && $3 ~ "/amuse-.*.ksh$" {
		print $1"\t"$3
		}
	===AWK===
# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-c^t^|^T-k^t^|^T-r^t^|^Ucommand^u^]
	         Starter for ^Samuse^s.
	           ^T-c^t  Clean up ^S\$AMUSE_RUN_DIR^s.
	           ^T-k^t  Kill any running instances.
	           ^T-r^t  Restart (stop then start).
	           ^T-s^t  Show running instances.
	         Or you can use one of the ^Ucommand^u words:
	           ^Tstart^t, ^Tstop^t, ^Tkill^t, ^Trestart^t, or ^Tcleanup^t.
	               ^GNote: ^Bkill^b is an alias for ^Bstop^b.^g
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
while getopts ':ckrsh' Option; do
	case $Option in
		c)	ACTION=CleanUp; ACCEPTCMD=false;					;;
		k)	ACTION=Stop;	ACCEPTCMD=false;					;;
		r)	ACTION=Restart;	ACCEPTCMD=false;					;;
		s)	ACTION=Status;	ACCEPTCMD=false;					;;
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
function get-running-info { # {{{1
	integer i=0
	unset status_pids status_names
	set -- $(pgrep -lf B/amuse| awk "$awk_status_pgm")
	while (($#)); do
		status_pids[i]=$1
		status_names[i]=${2##*/}
		shift 2
		((i++))
	done
	status_num=$i
	return 0
} # }}}1
function check-status { # {{{
	SERVER_IS_RUNNING=false
	UI_IS_RUNNING=false
	WATCH_TIME_IS_RUNNING=false
	get-running-info
	((status_num))|| return 0
	integer i=0
	while ((i<status_num)); do
		case ${status_names[i]} in
			amuse-server*)		SERVER_IS_RUNNING=true;			;;
			amuse-ui*)			UI_IS_RUNNING=true;				;;
			amuse-watchtime*)	WATCH_TIME_IS_RUNNING=true;		;;
			*) die						\
				'Programmer error:'		\
				"status_name is ^B${status_names[i]}"
				;;
		esac
		((i++))
	done
} # }}}
function start-in-background { # {{{1
	local scriptname scriptpath isrunning
	$SYSTEMS_ARE_GO || return 1
	roll "$@"; set -- "${reply[@]}"
	scriptname=$1
	notify "^F{2}Starting^f: $scriptname"
	scriptpath="$AMUSE_SCRIPT_PATH/$scriptname.ksh"
	shift
	nohup >~/log/$scriptname.log 2>&1 "$@" $scriptpath &
	isrunning=$(ps -ocommand= -p $!)
	[[ -n $isrunning ]]|| {
		SYSTEMS_ARE_GO=false
		warn "Could not start ^S$1^s."
	  }
} # }}}
function clean-ui { # {{{1
	print 'Clearing ui-pid'
	: >ui-pid
} # }}}1
function start-ui { # {{{1
	[[ -s ui-pid ]]&& clean-ui
	set -- /usr/local/bin/st -c amuse-ui -T amuse
	start-in-background "$@" amuse-ui	# options first, server name last
} #}}}1
function clean-server { # {{{1
	print 'Clearing server-pid and sigpipe'
	: >server-pid
	rm -f sigpipe
} # }}}1
function start-server { #{{{1
	[[ -s server-pid ]]&& clean-server
	start-in-background amuse-server
} #}}}
function clean-watchtime { # {{{1
	print 'Clearing watchtime-pid'
	: >watchtime-pid
} # }}}1
function start-watchtime { # {{{1
	[[ -s watchtime-pid ]]&& clean-watchtime
	start-in-background amuse-watchtime
} # }}}1
function clean-if-not-clean { # {{{1
	local isrunning name
	isrunning=$1
	name=$2
	if ! $isrunning; then
		notify "Cleaning ^B$name^b"
		clean-$name
	fi
} # }}}1
function CleanUp { # {{{1
	# short circut
	[[ -s ui-pid || -s server-pid || -s watchtime-pid ]]|| return 0

	check-status
	clean-if-not-clean $SERVER_IS_RUNNING		server
	clean-if-not-clean $UI_IS_RUNNING			ui
	clean-if-not-clean $WATCH_TIME_IS_RUNNING	watchtime

} #}}}1
function start-if-not-started { # {{{1
	local isrunning name
	isrunning=$1
	name=$2
	if $isrunning; then
		warn "^B$name^b is already running"
	else
		start-$name
	fi
} # }}}1
function Start { #{{{1
	local BUF

	BUF="$(head -n 3 played.lst)"
	>played.lst print -- "$BUF"

	check-status
	start-if-not-started $SERVER_IS_RUNNING			server
	start-if-not-started $UI_IS_RUNNING				ui
#	start-if-not-started $WATCH_TIME_IS_RUNNING		watchtime

} #}}}1
function Stop { #{{{1
	local p i
	for s in TERM WAIT KILL; do
		get-running-info
		p=$status_num
		((p))|| break
		[[ $s == WAIT ]]&& { sleep 0.5; continue;}
		i=0
		while ((i<p)); do
			notify "^F{9}Stopping^f: ($s) ${status_names[i]}"
			kill -$s ${status_pids[i]}
			((i++))
		done
	done
} #}}}1
function Restart { Stop; sleep 0.5; Start; sleep 0.5; }
function Status { # {{{1
	local i procnum
	typeset -L7 pid
	get-running-info
	procnum=$status_num
	i=0; while ((i<procnum)); do
		pid=${status_pids[i]}
		print -ru2 -- "  $pid ${status_names[i]}"
		((i++))
	done
} # }}}
$ACCEPTCMD && (($#)) && { # {{{
	typeset -l option=$1
	case $option in
		start|open)			ACTION=Start;				;;
		cleanup)			ACTION=CleanUp;				;;
		stop|kill|close)	ACTION=Stop;				;;
		restart)			ACTION=Restart;				;;
		status)				ACTION=Status;				;;
		*)			die "Unknown command ^B$option^b"
						"Must be one of: ^Tstart stop restart cleanup^t"
					;;
	esac
	shift
} # }}}
(($#))&& die 'Too many arguments. Expected only one (1).'

needs amuse:env roll needs-cd
amuse:env
needs-cd -or-die "${AMUSE_RUN_DIR:?}"

$ACTION; $SYSTEMS_ARE_GO || Stop; exit

# Copyright (C) 2019 by Tom Davis <tom@greyshirt.net>.
