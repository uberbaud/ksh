#!/bin/ksh
# <@(#)tag:tw.yt.greyshirt.net,2022-08-10,02.45.15z/16438fe>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

BASE=httpd-savedat
SCRIPT=~/bin/perl/$BASE.pl
LOGFILE=~/log/$BASE.log
RESTART=false
THIS_PGM=${0##*/}

function get-pid { pgrep -f "^perl $SCRIPT\$"; }
function help { # {{{1
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
	       ^T$PGM help^t^|^T-h^t^|^T--help^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}1
function start { # {{{1
	local pid
	needs-file -or-die "$SCRIPT"

	pid=$(get-pid)
	[[ -x $SCRIPT ]]|| die "^B$SCRIPT^b is not executable."
	[[ -n ${pid} ]]&&
		die "$dBASE: already running (PID: ^B$pid^b)."

	rotate-logfiles "$LOGFILE"
	trap '' HUP
	notify "Starting $dBASE"
	$SCRIPT </dev/null 1>$LOGFILE 2>&1 &
} # }}}1
function stop { # {{{1
	local pid
	pid=$(get-pid)
	if [[ -n ${pid:-} ]]; then
		notify "Killing $dBASE (PID: ^B$pid^b)."
		kill $pid
	else
		warn "$dBASE: not running."
	fi
} #}}}1
function restart { # {{{1
	stop
	start
} # }}}1
function check { # {{{1
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
function running { get-pid >/dev/null; }

(($#>1))&& die "Too many parameters. Expected only one (1): ^Ucommand^u."
(($#))|| die "Missing required parameter ^Ucommand^u."
needs needs-file rotate-logfiles sparkle-path

desparkle "$BASE.pl"
dBASE=^B$REPLY^b

[[ $1 == @(-h|--help) ]]&& set -- help
[[ $1 == @(start|stop|restart|check|help|running) ]]||
	die "Unknown ^Ucommand^u ^B$1^b." "Try ^Ucommand^u ^Thelp^t"

"$1"; exit

# Copyright (C) 2022 by Tom Davis.
