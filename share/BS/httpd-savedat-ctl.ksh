#!/bin/ksh
# <@(#)tag:tw.yt.greyshirt.net,2022-08-10,02.45.15z/16438fe>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

BASE=httpd-savedat
SCRIPT=~/bin/perl/$BASE.pl
LOGDIR=~/log
LOGFILE=$LOGDIR/$BASE.log
RESTART=false
THIS_PGM=${0##*/}
VERBOSE=true
LOG_CTL=false

function get-pid { pgrep -f "^perl $SCRIPT\$"; }
function subcmd-help { # {{{1
	desparkle "$THIS_PGM"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^Tstart^t^|^Tstop^t^|^Trestart^t
	         daemonize or otherwise ${SCRIPT##*/}
	       ^T$PGM check^t
	         Show status.
	       ^T$PGM running^t
	         exits with status ^T0^t ^G(true)^g or ^T1^t ^G(false)^g
	       ^T$PGM commands^t
	         Lists all valid commands sorted alphabetically.
	       ^T$PGM help^t^|^T-h^t^|^T--help^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}1
function subcmd-start { # {{{1
	local pid

	needs-file -or-die "$SCRIPT"
	[[ -x $SCRIPT ]]|| die "^B$SCRIPT^b is not executable."

	pid=$(get-pid)
	[[ -z ${pid} ]]|| {
			$VERBOSE || exit
			die "$dBASE: already running (PID: ^B$pid^b)."
		}

	rotate-logfiles "$LOGFILE"
	trap '' HUP
	notify "Starting $dBASE"
	$SCRIPT </dev/null 1>$LOGFILE 2>&1 &
} # }}}1
function subcmd-stop { # {{{1
	local pid
	pid=$(get-pid)
	if [[ -n ${pid:-} ]]; then
		notify "Killing $dBASE (PID: ^B$pid^b)."
		kill $pid
	else
		warn "$dBASE: not running."
	fi
} #}}}1
function subcmd-restart { # {{{1
	subcmd-stop
	subcmd-start
} # }}}1
function subcmd-check { # {{{1
	local pid
	pid=$(get-pid)
	if [[ -n ${pid:-} ]]; then
		notify "$dBASE: running"
		set -- $(ps -p $pid -o'%cpu=,cputime=,start=,etime=,state=')
		set -- pid $pid cpu\ % $1 cpu\ time $2 start $3 elapsed $4 state $5
		printf '        %-9s: %s\n' "$@"
	else
		notify "$dBASE: not running"
	fi
} # }}}1
function subcmd-running { get-pid >/dev/null; }
function subcmd-commands { # {{{1
	awk -F'[ -]' '/^function subcmd-/ {print $3}' "$1" | sort
} # }}}1

(($#))|| die "Missing required parameter ^Ucommand^u."
while [[ $1 == -* ]]; do
	case ${1#-} in
		h|-help)	set '' 'help';				;;
		l|-log)	LOG_CTL=true;					;;
		q)		VERBOSE=false;					;;
		*)		die "Unknown flag ^B$1^b.";		;;
	esac
	shift
done
(($#>1))&& die "Too many parameters. Expected only one (1): ^Ucommand^u."
needs needs-file rotate-logfiles sparkle-path

desparkle "$BASE.pl"
dBASE=^B$REPLY^b

[[ $1 == @(start|stop|restart|check|help|running|commands) ]]||
	die "Unknown ^Ucommand^u ^B$1^b." "Try ^Ucommand^u ^Thelp^t"

$LOG_CTL && {
	needs-path -create -or-die "$LOGDIR"
	exec >>$LOGDIR/${0##*/}.log 2>&1
	date +'%Y-%m-%d %H:%M:%S %z'
}

subcmd-$1 "$0"; exit

# Copyright (C) 2022 by Tom Davis.
