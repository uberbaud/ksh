# <@(#)tag:csongor.greyshirt.net,2017-08-11:tw/03.12.38z/32b357f>
# ksh local profile
# vim: ts=4 ft=ksh

export PRINTER=poco

osrev=$(uname -r)
osarc=$(uname -m)
PKG_PATH=ftp://ftp4.usa.openbsd.org/pub/OpenBSD/$osrev/packages/$osarc
export PKG_PATH
export TZ=EST5EDT

eval "$(env -i perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)"

typeset -fu pre-prompt
export PS1=\
'$(pre-prompt)'\
'\[\e[33m\]['\
'\[\e[31m\]KSH '\
'\[\e[32m\]\u'\
'\[\e[33m\]@'\
'\[\e[32m\]\h '\
'\[\e[34m\]\W'\
'\[\e[33m\]]'\
'\[\e[48;5;224;31m\]$( local E=$?; ((E))&& printf "[%d]" $E )'\
'\[\e[0m\]\$ '
