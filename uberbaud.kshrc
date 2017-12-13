# @(#)[:KQ&%s2TwrVsrO`?xkIo&: 2017-08-11 03:12:38 tw@csongor.lan]
# ksh local profile
# vim: ts=4 ft=ksh

export EDITOR=/usr/local/bin/vim
export VISUAL=$EDITOR

osrev=$(uname -r)
osarc=$(uname -m)
PKG_PATH=ftp://ftp4.usa.openbsd.org/pub/OpenBSD/$osrev/packages/$osarc
export PKG_PATH
export TZ=EST5EDT

alias s=show

LOGPS1='\n'\
'%:KSH:% \D{%Y.%m.%d.%H.%M.%S.%z} \w\n'\
'\[\e[33m\]['\
'\[\e[32m\]$( local E=$?; ((E))|| printf "ok" )'\
'\[\e[48;5;224;31m\]$( local E=$?; ((E))&& printf " %d " $E )'\
'\[\e[0;33m\]]'\
'\[\\e[0;34m\]\$'\
'\[\e[0m\] '

typeset -fu pre-prompt
export PS1=\
'$(pre-prompt)'\
'\[\e[38;5;80m\]['\
'\[\e[38;5;21m\]KSH '\
'\[\e[38;5;12m\]\u'\
'\[\e[38;5;80m\]@'\
'\[\e[38;5;12m\]\h '\
'\[\e[34m\]\W'\
'\[\e[38;5;80m\]]'\
'\[\e[48;5;224;31m\]$( local E=$?; ((E))&& printf "[%d]" $E )'\
'\[\e[0m\]\$ '

