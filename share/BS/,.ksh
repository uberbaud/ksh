#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-08-15:tw/05.12.04z/5b15fe0>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

#exec 1>~/log/xlock.log 2>&1
#typeset -L4 -i10 LINENO
#PS4='$LINENO | ${0##*/} | '
#set -x

apmarg=''
pgm="${0##*/}"
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
function Warn { print -u2 "$pgm: $*"; }
(($#))&& { # {{{1
	case "$1" in
		##### STATE in RAM  #####
		?(-)S)	apmarg=-S;					;; # stand-by (light sleep)
		?(-)z)	apmarg=-z;					;; # suspend (deep sleep)
		##### STATE in SWAP #####
		?(-)Z)	apmarg=-Z;					;; # hibernate
		#########################
		-h) usage;							;;
		*)	Warn "Bad parameter: '$1'";		;;
	esac
	shift; (($#))&&
		Warn "Unexpected parameters: $*"
} # }}}1
BATUX=${LOCALBIN=${HOME:?}/.local/bin}/set-bg-per-battery.sh
needs apm get-exclusive-lock-or-exit release-exclusive-lock log xlock $BATUX

LOCK=twScreenLock
get-exclusive-lock-or-exit $LOCK

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

COMPTON=$(pgrep compton)
[[ -n $COMPTON ]]&& kill $COMPTON

xlock "${opts[@]}" &
xlock_pid=$!

[[ -x /usr/bin/sudo ]]&&	/usr/bin/sudo -K	# revoke sudo persistance
[[ -x /usr/bin/ssh-add ]]&&	/usr/bin/ssh-add -D	# clear ssh keys
(amuse:send-cmd pause)	# stop the music
sync					# if the battery runs out while we're hibernating

# suspend returns immediately, but suspension is in the future
[[ -n $apmarg ]]&& {
	sleep 0.5	# make sure xlock has had time to do its thing
	apm $apmarg
  }

# pause here untile we've unlocked the screen
wait $xlock_pid

# reset anything that needs resetting
[[ -n $COMPTON ]]&&
	compton -b --config $XDG_CONFIG_HOME/x11/compton.conf

$BATUX >>$HOME/log/battery-monitor

log timesheet xlock end || Warn $REPLY

# RESET SOME DEVICES, just in case, because you know, sometimes.
doas ifconfig iwm0 up
doas rcctl reload sndiod

# CLEAN UP
release-exclusive-lock $LOCK

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
