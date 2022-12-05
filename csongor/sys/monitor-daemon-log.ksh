#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2020-12-27,22.03.41z/27851fa>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

NOTES_DIR=${XDG_CACHE_HOME:?}/monitor-daemon-log
[[ -d $NOTES_DIR ]]|| mkdir -p "$NOTES_DIR"

THIS_PGM="${0##*/}"
(($#))&& { # {{{1
	typeset -- THIS_PGM="${0##*/}"
	desparkle "$THIS_PGM"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Monitors ^S/var/daemon^s for SOME changes, and updates files
	         for use by programs like ^Tdwm-bar-setter.ksh^t.
	===SPARKLE===
	exit 0
} # }}} 1
# AWK: NETPGM {{{1
NETPGM=$(</dev/stdin) <<-\
	\===AWK===
	/ port.*[ ,]active/ {i=$1}
	/^\tstatus:/		{s=$2}
	END {
		sub(":","",i)
		if (s == "active")	print i
		else 				print i":"s
	  }
	===AWK===
# }}}1
function read-loop { # {{{1
	local m d t h f M p
	while $CONTINUE; do
		read -r m d t h f M
		[[ $h == $HOST ]]|| continue
		case $f in
			(apmd:)
				print -- "$M" >$NOTES_DIR/power
				;;
			(@(dhclient|ifstated)*)
				ifconfig trunk0 | awk "$NETPGM" >$NOTES_DIR/network
				;;
			(cpuspeed:)
				print -- "$M" >$NOTES_DIR/cpu
				;;
			#(sensorsd*) ???
			(*)
				continue;
				;;
		esac
		set -- $NOTES_DIR/subscribers/*
		[[ $1 == */\* ]]&& continue
		for p; do
			kill -s "$(<$p)" ${p##*/} ||
				rm -f "$p"
		done
	done
	release-exclusive-lock "$THIS_PGM"
} # }}}1

THIS_PGM=${THIS_PGM%.*}
get-exclusive-lock -no-wait "$THIS_PGM" ||
	die "^B$THIS_PGM^b is already running."

[[ -d ~/log ]]|| mkdir ~/log
exec >~/log/${THIS_PGM%.*}.log 2>&1

CONTINUE=true

trap CONTINUE=false	INT QUIT TERM PIPE
trap - 				HUP TSTP INFO USR1 USR2

tail -f /var/log/daemon | read-loop; exit

# Copyright (C) 2020 by Tom Davis <tom@greyshirt.net>.
