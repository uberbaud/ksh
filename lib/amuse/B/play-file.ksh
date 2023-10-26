#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2023-10-25,23.38.37z/4d75354>

fLOG=${HOME:?}/log/amuse-player.log
action=played
AUDIODEVICE=$1
export AUDIODEVICE

print -- 0 >timeplayed
#======================================[ heavy lifter ]===============#
play-one-ogg "$2" ${3:-} 1>paused-at 2>>$fLOG 3>timeplayed &
#=====================================================================#
print $! >player-pid
wait $! || action=paused
: >player-pid
[[ -s again || -s paused-at ]]||
	move-played-to-history
print $action >sigpipe

# ft=ksh
