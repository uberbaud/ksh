#!/bin/ksh
# @(#)[:2nY0@+6ypedP@#VB~2}J: 2017-08-15 05:12:04 Z tw@csongor]
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

: ${FPATH:?Run from within KSH}

needs apm xlock log ${LOCALBIN:?}/set-bg-per-battery.sh
log timesheet xlock begin || warn $REPLY

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
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
# process -options {{{1
function bad_programmer {	# {{{2
	die 'Programmer error:'	\
		"  No getopts action defined for [1m-$1[22m."
  };	# }}}2
apmarg=''
while getopts ':hZzS' Option; do
	case $Option in
		Z)	apmarg=-Z;												;;
		z)	apmarg=-z;												;;
		S)	apmarg=-S;												;;
		h)	usage;													;;
		\?)	die "Invalid option: [1m-$OPTARG[22m.";				;;
		\:)	die "Option [1m-$OPTARG[22m requires an argument.";	;;
		*)	bad_programmer "$Option";								;;
	esac
done
# remove already processed arguments
shift $(($OPTIND - 1))
# ready to process non '-' prefixed arguments
# /options }}}1
function opts+ { # {{{1
	local i
	for i in "$@"; do
		opts[${#opts[*]}]="$i"
	done
} # }}}1

# opts: a negative number sets the maximum
opts+	-planfont	'-*-dejavu sans-bold-r-normal-*-*-160-*-*-p-*-ascii-*'
opts+	-mode		clock
opts+	-count		20
opts+	-size		-500
opts+	-username	' '
opts+	-password	' '
opts+	-info		"'I can't die but once.' -- Harriet Tubman"

xlock "${opts[@]}" &
xlock_pid=$!

[[ -x /usr/bin/sudo ]]&&	/usr/bin/sudo -K	# revoke sudo persistance
[[ -x /usr/bin/ssh-add ]]&&	/usr/bin/ssh-add -D	# clear ssh keys
pkill -SIGINT -f '^zsh: aMuse player'			# stop the music

# suspend returns immediately, but suspension is in the future
[[ -n $apmarg ]]&& {
	sleep 0.5	# make sure xlock has had time to do its thing
	apm $apmarg
  }

# pause here untile we've unlocked the screen

wait $xlock_pid

$LOCALBIN/set-bg-per-battery.sh >>$HOME/log/battery-monitor

log timesheet xlock end || -warn $REPLY


# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
