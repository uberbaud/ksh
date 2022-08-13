#!/bin/ksh
# <@(#)tag:tw.yt.greyshirt.net,2022-08-10,02.45.15z/16438fe>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

BASE=httpd-savedat
SCRIPT=~/bin/perl/$BASE.pl
LOGFILE=~/log/$BASE.log
RESTART=false
THIS_PGM=${0##*/}

[[ ${1:-} == r?(e?(s?(t?(a?(r?(t)))))) ]]&& { RESTART=true; shift; }
(($#))&& { # USAGE {{{1
	desparkle "$THIS_PGM"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^Trestart^t^]
	         daemonize httpd-savedat.pl
	           ^Trestartr^t  kill any running process.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}1
needs needs-file rotate-logfiles sparkle-path

sparkle-path "$SCRIPT"
sprkl_SCRIPT=$REPLY
pid=$(pgrep -f "^perl $SCRIPT\$") &&
	if $RESTART; then
		notify "Killing running $sprkl_SCRIPT (PID: ^B$pid^b)."
		kill $pid
	else
		die "$sprkl_SCRIPT is already running (PID: ^B$pid^b)."
	fi

needs-file -or-die "$SCRIPT"
[[ -x $SCRIPT ]]|| die "^B$SCRIPT^b is not executable."

rotate-logfiles "$LOGFILE"
trap '' HUP
$SCRIPT </dev/null 1>$LOGFILE 2>&1 &

# Copyright (C) 2022 by Tom Davis.
