# <@(#)tag:csongor.greyshirt.net,2017-08-11:tw/03.12.38z/32b357f>
# ksh local profile
# vim: ts=4 ft=ksh

export TZ=EST5EDT

typeset -fu pre-prompt
export PS1=\
'$(pre-prompt)'\
'\[\e[38;5;107m\]['\
'\[\e[38;5;19m\]KSH '\
'\[\e[38;5;12m\]\u'\
'\[\e[38;5;107m\]@'\
'\[\e[38;5;12m\]\h '\
'\[\e[34m\]\W'\
'\[\e[38;5;107m\]]'\
'\[\e[48;5;224;31m\]$( local E=$?; ((E))&& printf "[%d]" $E )'\
'\[\e[0m\]\$ '

