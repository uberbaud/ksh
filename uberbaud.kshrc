# @(#)[:Te#KVH6x!=bK#sbXKgkE 2017-08-11 03:23:36 tw@uberbaud.net]
# local ksh profile
# vim: ts=4 ft=sh

# mail
export EMAIL='tom@tbdavis.com'
export MAILCHECK=-1

# misc
export VULTR_XTERM_WINDOW_BG='#EEEEFF' VULTR_XTERM_WINDOW_FG='#111111'

osrev=$(uname -r)
osarc=$(uname -m)
PKG_PATH=ftp://ftp4.usa.openbsd.org/pub/OpenBSD/${osrev}/packages/$osarc
export PKG_PATH
export TZ=EST5EDT

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

