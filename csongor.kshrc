# <@(#)tag:csongor.greyshirt.net,2017-08-11:tw/03.12.38z/32b357f>
# ksh local profile
# vim: ts=4 ft=ksh

# paths
export PERL_CPANM_HOME=$xdgdata/cpanm
export PERLBREW_ROOT=$xdgdata/perl5/perlbrew
export PERLBREW_HOME=$xdgcache/perlbrew
export PERLBREW_SKIP_INIT=''
export PERLBREW_LIB=''
perlbrew_rc=$PERLBREW_ROOT/etc/perlbrew.ksh
[[ -f $perlbrew_rc ]]&& . $perlbrew_rc
export GOPATH=$xdgdata/go

# default apps
export BROWSER="$(<$xdgcfg/etc/browser)"

# mail
export EMAIL='tom@greyshirt.net'
export FETCHMAILHOME=$xdgcfg/fetchmail
export MAILCHECK=-1
export MAILDROP=/var/mail/$USER
export MAILPATH=''
export MAIL_HOME=$xdgcfg/mail
export MAILRC=$MAIL_HOME/mail.rc
export MBOX=$MAIL_HOME/mbox
export NMH=$xdgcfg/nmh
export MH=$NMH/config

# misc
export dskBROWSER=1
export dskWIDGIT=7
export dskXAPP=6
export CSONGOR_XTERM_WINDOW_BG='#FFFFFF' CSONGOR_XTERM_WINDOW_FG='#000000'
export CVSROOT='anoncvs@anoncvs4.usa.openbsd.org:/cvs'
export LESSKEY=$xdgcfg/less/lesskey.compiled
export PRINTER=poco

export TZ=EST5EDT

alias s=show
alias m=m-part
alias lua=lua53
alias facebook='firefox https://www.facebook.com && exit'

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
'\[\e[0m'\
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

E=''; R=''
ps4a="$E[44;37m"
ps4b="$E[44;33m"
ps4c="$E[0m"
PS4W=14
#    |....+....0....|
ps4p='              ' # the width of PS4W
export PS4=\
"$ps4a$ps4p$R"\
'${0##*/}'\
"$ps4b $E[\$(($PS4W-\${#LINENO}))G \$LINENO "\
"$ps4c "

true
