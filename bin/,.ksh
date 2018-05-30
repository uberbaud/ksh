#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-08-15:tw/05.12.04z/5b15fe0>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

apmarg=''
# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	: ${FPATH:?}
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t ^[^T-Z^t^|^T-z^t^|^T-S^t^]
	         Lock the screen and related things for securing the machine.
	         ^T-Z^t  Hibernate, suspend to disk.
	         ^T-z^t  Suspend (deep sleep).
	         ^T-S^t  Stand-by (light sleep).
	       ^T${PGM} -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
(($#))&& { # {{{1
	case "$1" in
		##### STATE in RAM  #####
		?(-)S)	apmarg=-S;					;; # stand-by (light sleep)
		?(-)z)	apmarg=-z;					;; # suspend (deep sleep)
		##### STATE in SWAP #####
		?(-)Z)	apmarg=-Z;					;; # hibernate
		#########################
		-h) usage;							;;
		*)	print -u2 "$0: Bad opt: '$1'";	;;
	esac
} # }}}1
function needs { # {{{1
	typeset badlist=""
	for x { [[ -n "$(whence "$x")" ]] || badlist="$badlist $x"; }
    [[ -z $badlist ]] || die "Missing needed executables:^[[1m$badlist^[[0m"
} # }}}1
function log { # {{{1
	typeset logdir logfile
	REPLY=""
	logdir="$HOME"/log
	[[ -d $logdir ]] || {
		REPLY="$REPLY, $logdir is not a directory, writing to \$HOME"
		logdir="$HOME"
	}
	logfile="$logdir/$1"
	shift
	print "$(date -u +'%Y-%m-%d %H:%M:%S Z')  " "$@" > "$logfile" || REPLY="$REPLY, problem writing to $logfile."
	REPLY="${REPLY#, }"
	[[ -z $REPLY ]]
} # }}}1
needs apm xlock log ${LOCALBIN=${HOME:?}/.local/bin}/set-bg-per-battery.sh

log timesheet xlock begin || warn $REPLY

# opts: a negative number sets the maximum
new-array opts
+opts	-planfont	'-*-dejavu sans-bold-r-normal-*-*-160-*-*-p-*-ascii-*'
+opts	-mode		clock
+opts	-count		20
+opts	-size		-500
+opts	-username	' '
+opts	-password	' '
+opts	-info		"'I can't die but once.' -- Harriet Tubman"

xlock "${opts[@]}" &
xlock_pid=$!

[[ -x /usr/bin/sudo ]]&&	/usr/bin/sudo -K	# revoke sudo persistance
[[ -x /usr/bin/ssh-add ]]&&	/usr/bin/ssh-add -D	# clear ssh keys
pkill -SIGINT -f '^zsh: aMuse player'			# stop the music
sync	# if the battery runs out while we're hibernating, ¿maybe?

# suspend returns immediately, but suspension is in the future
[[ -n $apmarg ]]&& {
	sleep 0.5	# make sure xlock has had time to do its thing
	apm $apmarg
  }

# pause here untile we've unlocked the screen

wait $xlock_pid

$LOCALBIN/set-bg-per-battery.sh >>$HOME/log/battery-monitor

log timesheet xlock end || -warn $REPLY
doas ifconfig iwm0 up # just in case, because you know, sometimes

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
