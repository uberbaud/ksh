# <@(#)tag:csongor.greyshirt.net,2017-04-20:tw/19.11.47z/4e02e72>
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
export URI_AUTHORITY='greyshirt.net'
export XDIALOG_NO_GMSGS=1	# Xdialog Gdk/GLib/Gtk will not g_log()
export KDOTDIR
[[ -d "${ENV%/*}" ]]&&
	KDOTDIR="${ENV%/*}"

# XDG paths
if [[ -d ${XDG_CONFIG_HOME:-~/.config} ]]; then
	XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-~/.config}
	if [[ -f $XDG_CONFIG_HOME/user-dirs.dirs ]]; then
		. $XDG_CONFIG_HOME/user-dirs.dirs
	fi
	for v in $(typeset +); do [[ $v == XDG_* ]]&& export $v; done

	[[ -z $KDOTDIR && -d $XDG_CONFIG_HOME/ksh ]]&&
		KDOTDIR=$XDG_CONFIG_HOME/ksh

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
SYSDATA=$xdgdata/sysdata
[[ -d $SYSDATA ]]&& export SYSDATA || unset SYSDATA

[[ -n $KDOTDIR ]]&& {
	K=$KDOTDIR			; KU=$KDOTDIR/$HOST
	F=$K/functions		; [[ -d FU=$KU/F ]]&& FU=$KU/F
	B=$K/bin			; [[ -d FB=$KU/B ]]&& FB=$KU/B
	H=$K/help

	[[ -d $KU ]]|| mkdir $KU
	export FPATH=$F${FU+:$FU}
	KHIST=$KDOTDIR/H/history
  }


# special history file stuff
histcache=$xdgcache/history
[[ -d $histcache ]]|| mkdir -p $histcache
fhist=$(mktemp $histcache/ksh-hist.XXXXXXXXXXXX)
if (($?)); then
	print '  \033[38;5;172mwarning\033[0m: Using common history.'
	fhist=${KHIST:-/tmp}
else
	histmark="# OLDHISTORY $(date -u +'%Y-%m-%d %H:%M:%S Z')"
	T="$(cat)" <<-===
	function ShHistCleanUp {
		local fhist KHIST
		fhist='$fhist'
		KHIST='$KHIST'
		awk '/^$histmark\$/{p=1;next}p' "\$fhist">>"\$KHIST" &&
			rm "\$fhist"
	}
	===
	eval "$T"
	add-exit-action ShHistCleanUp
	tail -n 127 $KHIST>$fhist
	print "$histmark" >>$fhist
fi

# paths
export me=$HOME/work/clients/me
export CPATH=$xdgdata/c
export HISTCONTROL=ignoredups:ignorespace
export HISTFILE=$fhist
export HISTSIZE=8191
export LD_LIBRARY_PATH=$CPATH/lib
export USR_CLIB=$CPATH/lib
export USR_INCL=$CPATH/api
export LOCALBIN=$xdgdata/bin
# LUA wants SEMICOLON separated PATTERNS, empty item is default
export LUA_PATH_5_3="$xdgdata/lua/5.3/?.lua;$xdgdata/lua/5.3/?/init.lua;;"
export LUA_CPATH_5_3="$xdgdata/lua/5.3/?.so;;"
export CARGO_HOME=$xdgcfg/cargo
export TEMPLATES_FOLDER=$xdgdata/templates
export TMPDIR=$xdgcache/temp
export USRBIN=$HOME/bin/ksh
export PERL_UNICODE=AS
export PSQLRC=$xdgcfg/pg/psqlrc

####### IMPORT LOCAL BITS
[[ -f $KU/kshrc ]]&& . $KU/kshrc

# have cpanm install things where we want them
export USR_PLIB=$xdgdata/lib/perl5
export PERL5LIB=$USR_PLIB
# ^ add? -> # ${PERLBREW_LIB:+:$PERLBREW_LIB}
export PERL_MB_OPT="--install_base $USR_PLIB"
export PERL_MM_OPT="INSTALL_BASE=$USR_PLIB"


####### SET PATH
[[ -d $HOME/bin ]]&&
	[[ :$PATH: == *:$HOME/bin:*		]]|| PATH="$HOME/bin:$PATH";

#[[ :$PATH: == *:$RAKUDO_BIN:*		]]|| PATH="$RAKUDO_BIN:$PATH"
PERLBREW_BIN=$PERLBREW_CURRENT/bin
[[ :$PATH: == *:$PERLBREW_BIN:*		]]|| PATH="$PERLBREW_BIN:$PATH"
[[ :$PATH: == *:$MMH_BIN_PATH:*		]]|| PATH="$MMH_BIN_PATH:$PATH"
[[ :$PATH: == *:$LOCALBIN:*			]]|| PATH="$LOCALBIN:$PATH"
[[ :$PATH: == *:$USRBIN:*			]]|| PATH="$USRBIN:$PATH"
[[ :$PATH: == *:/usr/games:*		]]|| PATH="$PATH:/usr/games"
[[ :$PATH: == *:${JDK_PATH:-///}:*	]]|| PATH="$PATH:$JDK_PATH"

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
export KAKOUNE_POSIX_SHELL=/usr/local/bin/dash

# ==== DEFAULT APPS
# handle whether  EDITOR or VISUAL was set in $HOST.kshrc
[[ -z ${VISUAL:-${EDITOR:-}} ]]&& {
	L=/usr/local/bin; S=/usr/bin; U=$HOME/.local/bin
	for VISUAL in $L/nvim $L/vim $U/vis $L/vis $L/vise $S/vi; do
		[[ -x $VISUAL ]]&& break
	done
	unset L S U
  }

case $VISUAL in
	*/nvim)
		[[ -d $xdgcfg/nvim ]]&&
			export MYVIM=$xdgcfg/nvim
		;;
	*/vim)
		[[ -d $xdgcfg/vim ]]&&
			export MYVIM=$xdgcfg/vim
		[[ -n $MYVIM && -f $MYVIM/vimrc ]]&& {
			export MYVIMRC=$MYVIM/vimrc
			export VIMINIT="so $MYVIMRC"
		  }
		;;
	*/vi)
		[[ -f $xdgcfg/vi/nex.rc ]]&&
			export NEXINIT=$xdgcfg/vi/nex.rc
		[[ -f $xdgcfg/vi/ex.rc ]]&&
			export EXINIT=$xdgcfg/vi/ex.rc
		;;
	# */vis?(e)) Handles $xdgcfg just fine, thank you.
esac

VISUAL=${VISUAL:-${EDITOR:-}}
EDITOR=${EDITOR:-${VISUAL:-ed}}
FCEDIT=${FCEDIT:-$EDITOR}
export ${VISUAL:+VISUAL} EDITOR FCEDIT

export CC="$(command -v clang)"
export CXX="$(command -v clang++)"
export PAGER=/usr/bin/less
#export AUTOCONF_VERSION=$(
#	/bin/ls /usr/local/bin/autoconf-*	|
#		awk -F- '{print $NF}'			|
#		sort -nr						|
#		head -n 1
#  )
export AUTOCONF_VERSION=2.69
#export AUTOMAKE_VERSION=$(
#	/bin/ls /usr/local/bin/automake-*	|
#		awk -F- '{print $NF}'			|
#		sort -nr						|
#		head -n 1
#)
export AUTOMAKE_VERSION=1.16
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
# and some special love for amuse: bits
amuse:create-cmd-wrappers
# noglobs
for i in cowmath math note; { alias $i="noglob $i"; }
alias mathcow="noglob cowmath"
# askfirst all commands that use ssh
for i in ssh scp sftp rsync;	{ alias "$i=ssh-askfirst $i"; }
# Make fully qualified known hosts into aliases for sshing to that host
for i in $(grep '\.' $K/completions/ssh); do
	alias "$i=ssh $i"
done
# FPATH functions are implicitly autoloaded, but the completion 
# mechanism doesn't know about them unless we explicitly autoload them
IFS=:
for p in $FPATH; { for i in $p/*; { typeset -fu "${i##*/}"; } }
IFS=" $TAB$NL"
# clean up
unset p i

alias clear='f-clear ' # expand alias of $2
alias cls='clear colorls $LS_OPTIONS'
alias doas='as-root '
alias i-can-haz-inet='i-can-haz-inet;E=$?;print -r -- "  $REPLY";(return $E)&&:'
alias ls='/usr/local/bin/colorls $LS_OPTIONS'
alias noglob='set -f;noglob '; function noglob { set +f; ("$@"); }
alias hush='>/dev/null 2>&1 '
alias no2='2>/dev/null '
alias noerr='2>/dev/null '
alias cd='_u="$-"; set -u; f-cd'
alias prn="printf '  \e[35m｢\e[39m%s\e[35m｣\e[39m\n'"
alias vncsam='vncviewer -x11cursor -noraiseonbeep sam.lan'

alias k='fc -s'
alias ff='find0 -type f'
alias fd='find0 -type d'
alias fn='find0 -name'
alias ffn='find0 -type f -name'
alias fdn='find0 -type d -name'
alias x0='xargs -0'

for s in $(getent shells); do
	[[ $s == $SHELL ]]&& continue
	alias ${s##*/}="reshell $s"
done
unset s

VISED=/usr/local/bin/vis
[[ -x $VISED ]]&& alias vised="VISUAL=\"$VISED\" v" || unset VISED
#LUA_PATH=		# lua modules paths
#LUA_CPATH=		# C libraries paths
#LUA_PATH_5_3=		# lua modules paths; versioned vars override standard
#LUA_CPATH_5_3=		# C libraries paths; versioned vars override standard

[[ -n $KDOTDIR ]]&& {
	KCOMPLETE=$KDOTDIR/completions
	: run in sub-shell for exceptions sake; (
		makeout=$KCOMPLETE/make.out
		get-exclusive-lock completion-make
		make -C $KCOMPLETE >$KCOMPLETE/make.out
		[[ -s $makeout ]]&& {
			notify 'Recompiled completion modules:'
			COLUMNS=${COLUMNS:-$(tput col)}
			column -c $((COLUMNS-8)) $makeout|expand|sed -e 's/^/    /'
		  }
		rm $makeout
		release-exclusive-lock completion-make
	)
	. $KCOMPLETE/completions.ksh
  }
