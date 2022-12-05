#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-07-23:tw/07.45.56z/483e53e>
set -u

THIS_PGM=${0##*/}; THIS_PGM=${THIS_PGM%.ksh}
LOG=$HOME/log/$THIS_PGM
LOCALBIN=$HOME/local/bin
Watch=$LOCALBIN/watch-file
AlertUser=$LOCALBIN/handle-patch.ksh
MsgFile=/var/planB/syspatch.announce

function Die { # {{{1
	print -ru2 -- "$*"
	date +"### ENDING $THIS_PGM: %Y-%m-%d %H:%M:%S %z"
	exit 1
} # }}}1
function CleanUp { # {{{1
	release-exclusive-lock "$THIS_PGM"
	print "$THIS_PGM exclusive lock released"
} # }}}1

get-exclusive-lock -no-wait "$THIS_PGM" ||
	Die "$THIS_PGM is already running."
trap CleanUp EXIT

# create and use new log
exec >>$LOG 2>&1

date +"### STARTING $THIS_PGM: %Y-%m-%d %H:%M:%S %z"

[[ -x $Watch ]]||		Die "No exectuable $Watch bin."
[[ -x $AlertUser ]]||	Die "No exectuable $AlertUser bin."
[[ -f $MsgFile ]]||		Die "No message file $MsgFile."

while $Watch $MsgFile; do $AlertUser; done; exit

# Copyright (C) 2016 by Tom Davis <tom@greyshirt.net>.
