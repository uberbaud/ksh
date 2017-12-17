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
else
	XDG_CONFIG_HOME=$HOME/.config
	XDG_DATA_HOME=$HOME/.local
	XDG_CACHE_HOME=$HOME/.local/cache

	mkdir -p $XDG_CONFIG_HOME	>/dev/null 2>&1
	mkdir -p $XDG_DATA_HOME		>/dev/null 2>&1
	mkdir -p $XDG_CACHE_HOME	>/dev/null 2>&1
fi
xdgdata=$XDG_DATA_HOME
xdgcfg=$XDG_CONFIG_HOME
xdgcache=$XDG_CACHE_HOME

# special history file stuff
KHIST=$KDOTDIR/history
histcache=$xdgcache/history
[[ -d $histcache ]]|| mkdir -p $histcache
fhist=$(mktemp $histcache/ksh-hist.XXXXXXXXXXXX)
if (($?)); then
	print '  \033[38;5;172mwarning\033[0m: Using common history.'
	fhist=$KHIST
else
	histmark="# OLDHISTORY $(date -u +'%Y-%m-%d %H:%M:%S Z')"
	trap "awk '/^$histmark\$/{p=1;next}p' $fhist>>$KHIST && rm $fhist" EXIT
	tail -n 127 $KHIST>$fhist
	print "$histmark" >>$fhist
fi

# paths
export me=$HOME/work/clients/me
export FPATH=$KDOTDIR/functions
export HISTCONTROL=ignoredups:ignorespace
export HISTFILE=$fhist
export HISTSIZE=8191
export LD_LIBRARY_PATH=$xdgdata/c/lib
export LOCALBIN=$xdgdata/bin
export PERL5LIB=$xdgdata/perl5/twlib
export RAKUDO_HOME=$xdgdata/rakudo
export RAKUDO_BIN=$RAKUDO_HOME/install/bin
	RAKUDO_BIN=$RAKUDO_BIN:$RAKUDO_HOME/install/share/perl6/site/bin
export TEMPLATES_FOLDER=$xdgdata/templates
export TMPDIR=$xdgdata/temp
export USRBIN=$HOME/bin/ksh
export USR_CLIB=$xdgdata/c/lib
export PERL_UNICODE=AS
export USR_PLIB=$PERL5LIB

####### IMPORT LOCAL BITS
[[ -f $KDOTDIR/$HOST.kshrc ]]&& . $KDOTDIR/$HOST.kshrc

####### SET PATH
[[ -d $HOME/bin ]]&&
	[[ :$PATH: == *:$HOME/bin:*		]]|| PATH="$HOME/bin:$PATH";

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

# default apps
if   [[ -f /usr/local/bin/nvim ]]; then
	export MYVIM=$HOME/.config/nvim
	export EDITOR=/usr/local/bin/nvim
elif [[ -f /usr/local/bin/vim ]]; then
	export MYVIM=$HOME/.config/vim
	export MYVIMRC=$MYVIM/vimrc
	export VIMINIT="so $MYVIMRC"
	export EDITOR=/usr/local/bin/vim
else
	export EDITOR=/usr/bin/vi
fi
export VISUAL=$EDITOR
export FCEDIT=$EDITOR

export CC=$SYSLOCAL/bin/clang
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
	for i in $F/$p-*; { i="${i#$F/}"; alias "${i#$p-}=$i"; }
done
# noglobs
for i in cowmath math note; { alias $i="noglob $i"; }
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
alias i-can-haz-inet='i-can-haz-inet;E=$?;printf "  %s\n" "$REPLY";(return $E)&&:'
alias ls='/usr/local/bin/colorls $LS_OPTIONS'
alias noglob='set -f;noglob '; function noglob { set +f; ("$@"); }
alias prn="printf '  \e[35m｢\e[39m%s\e[35m｣\e[39m\n'"
alias reboot='doas reboot'

for s in $(getent shells); do
	[[ $s == $SHELL ]]&& continue
	alias ${s##*/}="reshell $s"
done
unset s

KCOMPLETE=$KDOTDIR/completions
makeout=$KCOMPLETE/make.out
while [[ -f $makeout ]] { sleep 0.1; }
make OS_VER="$(uname -r)" -C $KCOMPLETE >$KCOMPLETE/make.out
[[ -s $makeout ]]&& {
	notify 'Recompiled completion modules:'
	column -c $((COLUMNS-8)) $makeout|expand|sed -e 's/^/    /'
  }
rm $makeout
. $KDOTDIR/completions/completions.ksh
