# @(#)[:SR4?YKx^=i2MU(j$#uH?: 2017/08/01 02:52:13 tw@csongor.lan]
# ksh profile
# vim: ts=4 ft=ksh

# we are NOT sourcing /etc/ksh.kshrc because it does way too much stuff we 
# don't need. But these come from there.
export me=$HOME/work/clients/me
export UID=${UID:-$(id -u)}
export USER=${USER:-$(id -un)}
export LOGNAME=$USER
export HOME="$(getent passwd $USER | awk -F: '{print $6}')"
TTY="${TTY:-$(basename "$(tty)")}"
export HOSTNAME=${HOSTNAME:-$(uname -n)}
export HOST=${HOSTNAME%%.*}
[[ -n $console ]]|| {
	console=$(sysctl kern.consdev)
	console=${console#*=}
  }

export SYSLOCAL=/usr/local
export ISO_DATE='%Y-%m-%d %H:%M:%S %z'

# XDG paths
if [[ -d ${XDG_CONFIG_HOME:-~/.config} ]]; then
	XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-~/.config}
	if [[ -f $XDG_CONFIG_HOME/user-dirs.dirs ]]; then
		. $XDG_CONFIG_HOME/user-dirs.dirs
	fi
	for v in $(typeset +); do [[ $v == XDG_* ]]&& export $v; done

	if [[ -d $XDG_CONFIG_HOME/ksh ]]; then
		export KDOTDIR=$XDG_CONFIG_HOME/ksh
		K=$KDOTDIR
		F=$K/functions
		B=$K/bin
	fi
fi
xdgdata=$XDG_DATA_HOME
xdgcfg=$XDG_CONFIG_HOME
xdgcache=$XDG_CACHE_HOME

# paths
export FPATH=${KDOTDIR}/functions
export LOCALBIN=${xdgdata}/bin
export PERL_CPANM_HOME=${xdgdata}/cpanm
export PERLBREW_ROOT=${xdgdata}/perl5/perlbrew
export PERLBREW_BIN=${PERLBREW_ROOT}/bin
export PERLBREW_MANPATH=$PERLBREW_ROOT/perls/perl-5.24.1/man
export PERLBREW_PERL=perl-5.24.1
export PERLBREW_PATH=$PERLBREW_BIN:$PERLBREW_ROOT/perls/perl-5.24.1/bin
export PERLBREW_HOME=${xdgcache}/perlbrew
export PERLBREW_SKIP_INIT=''
export PERLBREW_LIB=''
export PERL5LIB=${xdgdata}/lib/perl
export TEMPLATES_FOLDER=${xdgdata}/templates
export TMPDIR=${xdgdata}/temp
export USRBIN=${HOME}/bin/ksh
export USRLIB=${xdgdata}/lib
export USR_CLIB=${xdgdata}/lib/c
export PERL_UNICODE=AS
export USR_PLIB=$PERL5LIB

[[ :$PATH: == *:$PERLBREW_PATH:*	]]|| PATH=$PERLBREW_PATH:$PATH
[[ :$PATH: == *:$LOCALBIN:*			]]|| PATH=$LOCALBIN:$PATH
[[ :$PATH: == *:$USRBIN:*			]]|| PATH=$USRBIN:$PATH

# input, locale, and such
set -o vi -o vi-tabcomplete
set -o braceexpand -o vi -o ignoreeof -o physical

export GTK_IM_MODULE=xim
export INPUTRC=$xdgcfg/init/input.rc
export LANG=en_US.UTF-8
for v in ALL COLLATE CTYPE MESSAGES MONETARY NUMERIC TIME; do
	export LC_$v=$LANG
done
export PRINTER=poco
export QT_IM_MODULE=xim
export XCOMPOSEFILE=$xdgcfg/x11/Compose.tw
export XMODIFIERS='@im=none'

# init files and paths
export BC_ENV_ARG=$xdgcfg/etc/bc.rc
export BZR_HOME=$xdgcfg/bzr
export CALENDAR_DIR=$xdgcfg/calendar
export HGRCPATH=$xdgcfg/hg

# editor
export MYVIM=$xdgcfg/vim
export MYVIMRC=$MYVIM/vimrc
export VIMINIT="so $MYVIMRC"

# default apps
export BROWSER=$HOME/bin/start-firefox
export CC=$SYSLOCAL/bin/clang
export EDITOR=$SYSLOCAL/bin/vim
export PAGER=/usr/bin/less

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
export CLICOLOR=1
export COLORTERM=truecolor
export CSONGOR_XTERM_WINDOW_BG='#FFFFFF' CSONGOR_XTERM_WINDOW_FG='#000000'
export CVSROOT='anoncvs@anoncvs4.usa.openbsd.org:/cvs'
export GNUPGHOME=$xdgdata/gnupg
export GPG_AGENT=$SYSLOCAL/bin/gpg-agent
export ISO_DATE='%Y-%m-%d %H:%M:%S %z'
export ISO_WEEK='%G-W%V-%u'
export LESS='-RcgiSw#8'
export LESSHISTFILE='-'
export LS_OPTIONS='-FG'

osrev=$(uname -r)
osarc=$(uname -m)
PKG_PATH=ftp://ftp4.usa.openbsd.org/pub/OpenBSD/$osrev/packages/$osarc
export PKG_PATH
export POD_TO_TEXT_ANSI=1
export TZ=EST5EDT

#-----8<------8<-----
export dskBROWSER=1
export dskWIDGIT=7
export dskXAPP=6
#----->8------>8-----

TAB='	'
NL='
'

LOGPS1='\n'\
'%:KSH:% \D{%Y.%m.%d.%H.%M.%S.%z} \w\n'\
'\[\e[33m\]['\
'\[\e[32m\]$( local E=$?; ((E))|| printf "ok" )'\
'\[\e[48;5;224;31m\]$( local E=$?; ((E))&& printf " %d " $E )'\
'\[\e[0;33m\]]'\
'\[\\e[0;34m\]\$'\
'\[\e[0m\] '

export PS1=\
'$(forceline)'\
'\[\e[33m\]['\
'\[\e[31m\]KSH '\
'\[\e[32m\]\u'\
'\[\e[33m\]@'\
'\[\e[32m\]\h '\
'\[\e[34m\]\W'\
'\[\e[33m\]]'\
'\[\e[48;5;224;31m\]$( local E=$?; ((E))&& printf "[%d]" $E )'\
'\[\e[0m\]\$ '

unalias stop r
typeset -fu r help

alias cd='newcd'
alias cls='clear; ls'
alias doas='doas '
alias ls='/usr/local/bin/colorls ${LS_OPTIONS}'
alias math='noglob math'
alias noglob='set -f;noglob '; function noglob { "$@"; set +f; }
alias prn="printf '  \e[35m｢\e[39m%s\e[35m｣\e[39m\n'"
alias cowmath='noglob cowmath'

. ${KDOTDIR}/completions
