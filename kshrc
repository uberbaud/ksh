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
export me=$HOME/work/clients/me
export FPATH=$KDOTDIR/functions
export HISTFILE=$KDOTDIR/history
export HISTSIZE=8191
export LOCALBIN=$xdgdata/bin
export PERL5LIB=$xdgdata/lib/perl
export RAKUDO_HOME=$xdgdata/rakudobrew
export RAKUDO_BIN=$RAKUDO_HOME/bin
export TEMPLATES_FOLDER=$xdgdata/templates
export TMPDIR=$xdgdata/temp
export USRBIN=$HOME/bin/ksh
export USRLIB=$xdgdata/lib
export USR_CLIB=$xdgdata/lib/c
export PERL_UNICODE=AS
export USR_PLIB=$PERL5LIB

####### IMPORT LOCAL BITS
[[ -f $KDOTDIR/$HOST.kshrc ]]&& . $KDOTDIR/$HOST.kshrc

[[ -d $HOME/bin ]]&& {
[[ :$PATH: == *:$HOME/bin:*			]]|| PATH="$HOME/bin:$PATH"; }

[[ :$PATH: == *:$RAKUDO_BIN:*		]]|| PATH="$RAKUDO_BIN:$PATH"
[[ :$PATH: == *:$LOCALBIN:*			]]|| PATH="$LOCALBIN:$PATH"
[[ :$PATH: == *:$USRBIN:*			]]|| PATH="$USRBIN:$PATH"
[[ :$PATH: == *:/usr/games:*		]]|| PATH="$PATH:/usr/games"

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
export FCEDIT=$EDITOR
export PAGER=/usr/bin/less
export VISUAL=$EDITOR

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
	for i in $F/$p-*; { i="${i#$F/}"; alias "${i#$p-}=$i"; }
done
# noglobs
for i in cowmath find math note; { alias $i="noglob $i"; }
# askfirst all commands that use ssh
for i in ssh scp sftp rsync;	{ alias "$i=ssh-askfirst $i"; }
# known hosts are commands to ssh to that host
set -A known_hosts -- $(awk -F'[ ,]' '{print $1}' $xdgcfg/ssh/known_hosts)
for i in "${known_hosts[@]}";	{ alias "$i=ssh $i"; }
# FPATH functions are implicitly autoloaded, but the completion 
# mechanism doesn't know about them unless we explicitly autoload them
IFS=:
for p in $FPATH; { for i in $F/*; { typeset -fu "${i##*/}"; } }
IFS=" $TAB$NL"
# clean up
unset p i

alias clear='f-clear ' # expand alias of $2
alias cls='clear colorls $LS_OPTIONS'
alias doas='doas '
alias halt='doas halt'
alias i-can-haz-inet='i-can-haz-inet; printf "  %s\n" "$REPLY"'
alias ls='/usr/local/bin/colorls $LS_OPTIONS'
noglob() { "$@"; set +f; }; alias noglob='set -f;noglob '
alias prn="printf '  \e[35m｢\e[39m%s\e[35m｣\e[39m\n'"
alias reboot='doas reboot'

for s in $(getent shells); do
	[[ $s == $SHELL ]]&& continue
	alias ${s##*/}="reshell $s"
done
unset s

. $KDOTDIR/completions
