# @(#)[:KQ&%s2TwrVsrO`?xkIo&: 2017-08-11 03:12:38 tw@csongor.lan]
# ksh local profile
# vim: ts=4 ft=ksh

# paths
export PERL_CPANM_HOME=${xdgdata}/cpanm
export PERLBREW_ROOT=${xdgdata}/perl5/perlbrew
export PERLBREW_BIN=${PERLBREW_ROOT}/bin
export PERLBREW_MANPATH=$PERLBREW_ROOT/perls/perl-5.24.1/man
export PERLBREW_PERL=perl-5.24.1
export PERLBREW_PATH=$PERLBREW_BIN:$PERLBREW_ROOT/perls/perl-5.24.1/bin
export PERLBREW_HOME=${xdgcache}/perlbrew
export PERLBREW_SKIP_INIT=''
export PERLBREW_LIB=''
export PRINTER=poco

# default apps
export BROWSER=$HOME/bin/surf

# mail
export EMAIL='tom@greyshirt.net'
export MAILCHECK=-1
export MAILDROP=/var/mail/$USER
export MAILPATH=''
export MAIL_HOME=$xdgcfg/mail
export MAILRC=$MAIL_HOME/mail.rc
export MBOX=$MAIL_HOME/mbox
export NMH=$xdgcfg/nmh
export MH=$NMH/config

# misc
export CSONGOR_XTERM_WINDOW_BG='#FFFFFF' CSONGOR_XTERM_WINDOW_FG='#000000'
export CVSROOT='anoncvs@anoncvs4.usa.openbsd.org:/cvs'

osrev=$(uname -r)
osarc=$(uname -m)
PKG_PATH=ftp://ftp4.usa.openbsd.org/pub/OpenBSD/$osrev/packages/$osarc
export PKG_PATH
export TZ=EST5EDT

#-----8<------8<-----
export dskBROWSER=1
export dskWIDGIT=7
export dskXAPP=6
#----->8------>8-----

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
'\[\e[33m\]['\
'\[\e[31m\]KSH '\
'\[\e[32m\]\u'\
'\[\e[33m\]@'\
'\[\e[32m\]\h '\
'\[\e[34m\]\W'\
'\[\e[33m\]]'\
'\[\e[48;5;224;31m\]$( local E=$?; ((E))&& printf "[%d]" $E )'\
'\[\e[0m\]\$ '

