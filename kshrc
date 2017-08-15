# @(#)[:SR4?YKx^=i2MU(j$#uH?: 2017/08/01 02:52:13 tw@csongor.lan]
# ksh profile
# vim: ts=4 ft=ksh

# we are NOT sourcing /etc/ksh.kshrc because it does way too much stuff we 
# don't need. But these come from there.
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
export TERM

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
export PERL5LIB=${xdgdata}/lib/perl
export TEMPLATES_FOLDER=${xdgdata}/templates
export TMPDIR=${xdgdata}/temp
export USRBIN=${HOME}/bin/ksh
export USRLIB=${xdgdata}/lib
export USR_CLIB=${xdgdata}/lib/c
export PERL_UNICODE=AS
export USR_PLIB=$PERL5LIB

####### IMPORT LOCAL BITS
[[ -f $KDOTDIR/$HOST.kshrc ]]&& . $KDOTDIR/$HOST.kshrc

[[ -d $HOME/bin ]]&& {
[[ :$PATH: == *:$HOME/bin:*			]]|| PATH="$HOME/bin:$PATH"; }

[[ :$PATH: == *:$PERLBREW_PATH:*	]]|| PATH="$PERLBREW_PATH:$PATH"
[[ :$PATH: == *:$LOCALBIN:*			]]|| PATH="$LOCALBIN:$PATH"
[[ :$PATH: == *:$USRBIN:*			]]|| PATH="$USRBIN:$PATH"

# input, locale, and such
set -o vi -o vi-tabcomplete
set -o braceexpand -o ignoreeof -o physical

export GTK_IM_MODULE=xim
export INPUTRC=$xdgcfg/init/input.rc
export LANG=en_US.UTF-8
for v in ALL COLLATE CTYPE MESSAGES MONETARY NUMERIC TIME; do
	export LC_$v=$LANG
done
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
export CC=$SYSLOCAL/bin/clang
export EDITOR=$SYSLOCAL/bin/vim
export PAGER=/usr/bin/less

# misc
export CLICOLOR=1
export COLORTERM=truecolor
export GNUPGHOME=$xdgdata/gnupg
export GPG_AGENT=$SYSLOCAL/bin/gpg-agent
export ISO_DATE='%Y-%m-%d %H:%M:%S %z'
export ISO_WEEK='%G-W%V-%u'
export LESS='-RcgiSw#8'
export LESSHISTFILE='-'
export LS_OPTIONS='-FG'

export POD_TO_TEXT_ANSI=1

TAB='	'
NL='
'
# For functions whose name conflicts with an executable in PATH, ksh 
# prefers the executable. To avoid this and allow explicit calls to the 
# functions or the executables, we name those functions with the 'f-' 
# prefix and then alias those to the name without the 'f-'. Everybody 
# wins.
for p in f amuse; do
	for f in $F/$p-*; { f="${f#$F/}"; alias "${f#$p-}=$f"; }
done
unset p f

alias cls='clear colorls ${LS_OPTIONS}'
alias doas='doas '
alias find='noglob find'
alias ls='/usr/local/bin/colorls ${LS_OPTIONS}'
alias math='noglob math'
alias noglob='set -f;noglob '; function noglob { "$@"; set +f; }
alias prn="printf '  \e[35m｢\e[39m%s\e[35m｣\e[39m\n'"
alias cowmath='noglob cowmath'

for s in $(getent shells); do
	[[ $s == $SHELL ]]&& continue
	alias ${s##*/}="reshell $s"
done
unset s

. $KDOTDIR/completions
