#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2020-12-28,06.42.49z/199bf5b>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

THIS_PGM="${0##*/}"
(($#))&& { # {{{1
	desparkle "$THIS_PGM"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Monitors CPU
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
function loop { # {{{1
	while $CONTINUE; do
		n=$(sysctl -n hw.cpuspeed)
		((n==CPU))|| {
			CPU=$n
			logger -p daemon.info -t cpuspeed $CPU
		  }
		sleep 1
	done
	release-exclusive-lock "$THIS_PGM"
} # }}}1

THIS_PGM=${THIS_PGM%.*}
get-exclusive-lock -no-wait "$THIS_PGM" ||
	die "^B$THIS_PGM^b is already running."

CONTINUE=true
trap CONTINUE=false	INT QUIT TERM PIPE
trap - 				HUP TSTP INFO USR1 USR2

[[ -d ~/log ]]|| mkdir ~/log
exec >~/log/${THIS_PGM%.*}.log 2>&1

typeset -i CPU=0

loop; exit

# Copyright (C) 2020 by Tom Davis <tom@greyshirt.net>.
