# <@(#)tag:csongor.greyshirt.net,2017-04-20:tw/19.11.47z/4e02e72>
# ksh profile
# vim: ts=4 ft=ksh

s=''
[[ ${SHSTATE:-} == ?(* )$$:P ]]&& {
	SHSTATE=${SHSTATE%%?( )$$:P}
	s=P
  }
[[ -o login ]]&& 		s=${s:-}l
[[ -o interactive ]]&&	s=${s:-}i
export SHSTATE=${SHSTATE:+$SHSTATE\ }$$${s:+:$s}
unset s

# ${RC_HAS_RUN:-false} && return
# we are NOT sourcing /etc/ksh.kshrc because it does way too much stuff we 
# don't need. But these come from there.
export SHORTPATH=${SHORTPATH:-$(getconf PATH)}
export UID=${UID:-$(id -u)}
export USER=${USER:-$(id -un)}
export LOGNAME=$USER
export HOME="$(getent passwd $USER | awk -F: '{print $6}')"
TTY="${TTY:-$(basename "$(tty)")}"
export HOSTNAME=${HOSTNAME:-$(uname -n)}
export HOST=${HOSTNAME%%.*}
export TERM

export SYSLOCAL=/usr/local
export URI_AUTHORITY='uberbaud.foo'

# parse ENV to find out where we are
KDOTDIR=${KDOTDIR:-$(dirname $(realpath -q "$ENV"))}
export KDOTDIR

# XDG paths
[[ -f ~/.xdg-base-dirs ]]&& . ~/.xdg-base-dirs
# per spec:
# https://specifications.freedesktop.org/basedir-spec/latest/ar01s02.html
# accessed: 2022-08-16 16:09:25 -0400
[[ -n $XDG_CACHE_HOME   ]]|| XDG_CACHE_HOME=$HOME/.cache
[[ -n $XDG_CONFIG_HOME  ]]|| XDG_CONFIG_HOME=$HOME/.config
[[ -n $XDG_DATA_HOME    ]]|| XDG_DATA_HOME=$HOME/.local/share
xdglocal=${xdglocal:-${XDG_DATA_HOME%/*}}
[[ $xdglocal == $HOME ]]&& print -ru2 -- "Warning: \$xdglocal := $xdglocal"
[[ -d $xdglocal ]]|| mkdir -p "$xdglocal"
[[ -n $XDG_RUNTIME_DIR  ]]|| XDG_RUNTIME_DIR=$xdglocal/run
[[ -n $XDG_STATE_HOME   ]]|| XDG_STATE_HOME=$xdglocal/state
[[ -n $XDG_DATA_DIRS    ]]|| XDG_DATA_DIRS=/usr/local/share:/usr/share
[[ -n $XDG_CONFIG_DIRS  ]]|| XDG_CONFIG_DIRS=/etc/xdg
xdgcfg=$XDG_CONFIG_HOME
xdgcache=$XDG_CACHE_HOME
xdgdata=$XDG_DATA_HOME
xdgrun=$XDG_RUNTIME_DIR
xdgstate=$XDG_STATE_HOME

[[ -f $xdgcfg/user-dirs.dirs ]]|| xdg-user-dirs-update
[[ -f $xdgcfg/user-dirs.dirs ]]&& . $xdgcfg/user-dirs.dirs

for v in $(typeset +); do
    [[ $v == XDG_* ]]|| continue
    export $v
    [[ $v == XDG_*_DIRS ]]&& continue
    eval D=\$$v
    [[ -d $D ]]|| mkdir -p "$D"
done

SYSDATA=$xdgdata/sysdata
[[ -d $SYSDATA ]]&& export SYSDATA || unset SYSDATA

[[ -z $KDOTDIR && -d $xdgcfg/ksh ]]&& KDOTDIR=$xdgcfg/ksh
[[ -n $KDOTDIR ]]&& {
	
	K=$KDOTDIR;			KU=$KDOTDIR/$HOST;		KS=$KDOTDIR/share
						F=$KU/F;				FS=$KS/FS
						B=$KU/B					BS=$KS/BS
						C=$KU/C					CS=$KS/CS
												H=$KS/HS
	L=$KDOTDIR/lib

	[[ -d $KU ]]|| mkdir $KU
	export FPATH=$F
	KHIST=$KU/history
  }
export KDOTDIR

export REPOS_HOME=$xdgdata/repos
export TREE_SITTER_LIBS=$xdgcache/tree-sitter/lib
	[[ -d $TREE_SITTER_LIBS ]]|| unset TREE_SITTER_LIBS

function -no-globs {
	local cmd prev recmd
	for cmd; do
		prev=$(alias $cmd) && recmd=${prev#"$cmd"=} || recmd=$cmd
		alias "$cmd"="noglob $recmd"
	done
}

####### IMPORT LOCAL BITS
[[ -f $KU/kshrc ]]&& . $KU/kshrc

# special history file stuff
histcache=$xdgcache/history
[[ -d $histcache ]]|| mkdir -p $histcache
fhist=$(mktemp $histcache/ksh-hist.XXXXXXXXXXXX)
if (($?)); then
	print '  \033[38;5;172mwarning\033[0m: Using common history.'
	fhist=${KHIST:-/tmp/history}
else
	histmark="# OLDHISTORY $(date -u +'%Y-%m-%d %H:%M:%S Z')"
	T="$(cat)" <<-===
	function ShHistCleanUp {
	    local fhist KHIST
	    fhist='$fhist'
	    KHIST='$KHIST'
	    if awk '/^$histmark\$/{p=1;next}p' "\$fhist">>"\$KHIST"; then
	        rm "\$fhist"
	    else
	        warn 'Did not update ^O\$^o^VK^v^B/H/history^b'
	    fi
	}
	===
	eval "$T"
	add-exit-actions ShHistCleanUp
	tail -n 127 $KHIST>$fhist
	print "$histmark" >>$fhist
fi

# paths
export HISTCONTROL=ignoredups:ignorespace
export HISTFILE=$fhist
export HISTSIZE=8191
export LOCALBIN=~/local/bin
# C
cflags[0]=-W'everything'
cflags[1]=-W'no-unsafe-buffer-usage'
cflags[2]=-f'diagnostics-show-option'
cflags[3]=-f'color-diagnostics'
export CFLAGS="${cflags[*]}"
export MAKECONF=${MAKECONF:-$xdgcfg/etc/ports-settings.mk}
[[ -f $MAKECONF ]]|| unset MAKECONF
USER_MK=$xdgcfg/etc/user.mk
export EXTRA_SYS_MK_INCLUDES="<$USER_MK>"
[[ -f $USER_MK ]]|| unset EXTRA_SYS_MK_INCLUDES USER_MK
# LUA 5.1
export LUA_PATH='/usr/local/share/lua/5.1/?.lua;./?.lua;/usr/local/share/lua/5.1/?/init.lua;/usr/local/lib/lua/5.1/?.lua;/usr/local/lib/lua/5.1/?/init.lua;/home/tw/local/luarocks/share/lua/5.1/?.lua;/home/tw/local/luarocks/share/lua/5.1/?/init.lua'
export LUA_CPATH='./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so;/home/tw/local/luarocks/lib/lua/5.1/?.so'
# LUA 5.3
# LUA wants SEMICOLON separated PATTERNS, empty item is default
export LUA_PATH_5_3="$xdgdata/lua/5.3/?.lua;$xdgdata/lua/5.3/?/init.lua;;"
export LUA_CPATH_5_3="$xdgdata/lua/5.3/?.so;;"
export CARGO_HOME=$xdgdata/cargo
export TEMPLATES_FOLDER=$xdgdata/templates
export TMPDIR=$xdgcache/temp
export TMUX_TMPDIR=$xdgcache/tmux
[[ -d $TMUX_TMPDIR ]]|| mkdir -p "$TMUX_TMPDIR"
export USRBIN=$HOME/bin/ksh
export PERL_CPANM_HOME=$xdgdata/cpanm
export PERL_UNICODE=AS
export PERLDOC='-MPod::Perldoc::ToTerm'
export PERLDOC_SRC_PAGER=$VISUAL
export PSQLRC=$xdgcfg/pg/psqlrc

# have cpanm install things where we want them
export USR_PLIB=$xdgdata/lib/perl5
export PERL5LIB=$USR_PLIB
# ^ add? -> # ${PERLBREW_LIB:+:$PERLBREW_LIB}
#export PERLBREW_BIN=$PERLBREW_CURRENT/bin
export PERL_MB_OPT="--install_base $xdgdata"
export PERL_MM_OPT="INSTALL_BASE=$xdgdata"
# similar but for raku
export RAKULIB=$xdgdata/lib/raku
export xRAKU_BASE=$xdgdata/rakudo

####### SET PATH
# sane start, but with installed (/usr/local) ahead of included (/usr/*)
PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/X11R6/bin
function wantpath { # {{{1
	[[ -d $1 && :$PATH: != *:$1:* ]]|| return
	if [[ $2 == P* ]]; then
		PATH="$1:$PATH"
	elif [[ $2 == A* ]]; then
		PATH="$PATH:$1"
	else
		warn "Bad ^SPATH^s placement: $2."	\
			'Expected ^TAPPEND^t or ^TPREPEND^t.'
	fi
} # }}}1
# PREPEND, so in reverse order
wantpath "$LOCALBIN"				PREPEND
wantpath "$HOME"/bin				PREPEND
wantpath "$USRBIN"					PREPEND
# APPEND, so in order
wantpath "$MMH_BIN_PATH"			APPEND
wantpath /usr/games					APPEND
wantpath "$xdgdata/bin"				APPEND # perl5lib
wantpath "$xdgdata/luarocks/bin"	APPEND
wantpath "$xRAKU_BASE/bin"			APPEND
wantpath "$CARGO_HOME/bin"			APPEND
wantpath "$OPAMROOT/default/bin"	APPEND # ocaml
wantpath "$JDK_PATH"				APPEND
wantpath "$ROFFTOOLS_PATH"			APPEND

# input, locale, and such
set -o vi -o vi-tabcomplete
set -o braceexpand -o ignoreeof -o physical

export INPUTRC=$xdgcfg/init/input.rc
[[ -n ${LC_CTYPE:-} ]]&& { # set in ~/.xsession
	export LANG=$LC_CTYPE
	# LC_ALL *overrides* all other LC_* setings, SO DON'T SET IT.
	for v in COLLATE MESSAGES MONETARY NUMERIC TIME; do
		export LC_$v=$LANG
	done
  }

# init files and paths
export BC_ENV_ARG=$xdgcfg/etc/bc.rc
export BZR_HOME=$xdgcfg/bzr
export CABAL_DIR=$xdgcfg/cabal
export HGRCPATH=$xdgcfg/hg

# ==== DEFAULT APPS
# handle whether  EDITOR or VISUAL was set in $HOST.kshrc
[[ -z ${VISUAL:-${EDITOR:-}} ]]&& {
	L=/usr/local/bin; S=/usr/bin; U=$HOME/local/bin
	for V in $U/nvim $L/nvim $L/vim $U/vis $L/vis $L/vise $S/vi; do
		[[ -x $V ]]&& { VISUAL=$V; break; }
	done
	unset V L S U
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
export AUTOCONF_VERSION=2.71
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
export ISO_DATE='%Y-%m-%d %H:%M:%S %z'
export ISO_WEEK='%G-W%V-%u'
export LESS='-RcgiSw#8'
export LESSHISTFILE='-'
export LS_OPTIONS='-FG'

export POD_TO_TEXT_ANSI=1

TAB='	'
NL='
'
############[ BEGIN FPATH SPECIALNESS ]###################################
ifs=$IFS; IFS=:; set -- $FPATH; IFS=$ifs

# For functions whose name conflicts with an executable in PATH, ksh 
# prefers the executable. To avoid this and allow explicit calls to the 
# functions or the executables, we name those functions with the 'f-' 
# prefix and then alias those to the name without the 'f-'. Everybody 
# wins.
for p { for i in $p/f-*; { i="${i#$p/}"; alias "${i#f-}=$i"; }; }

# do the -no-globs here, AFTER the FPATH/f-* processing
#-no-globs locate

# FPATH functions are implicitly autoloaded, BUT the completion 
# mechanism doesn't know about them unless we explicitly autoload them
for p { for i in $p/*; { typeset -fu "${i##*/}"; } }

# clean up
unset o p i
set --
############[ END FPATH SPECIALNESS ]#####################################

alias cd='_u="$-"; set -u; f-cd'
alias cdt='builtin cd "$(mktemp -d)"'
alias cls='clear colorls $LS_OPTIONS'
alias clear='f-clear '
alias doas='doas '
alias hush='>/dev/null 2>&1 '
alias k='fc -s'
alias localize-shared='"  $REPLY";(return $E)&&:'
if [[ -x /usr/local/bin/colorls ]]; then
	alias ls='/usr/local/bin/colorls $LS_OPTIONS'
else
	alias ls='/bin/ls $LS_OPTIONS'
fi
alias no2='2>/dev/null '
alias noerr='2>/dev/null '
# ==================================================== BEGIN: NOGLOB ===
alias noglob='[[ $- == *f* ]]|| { set -f; false; };noglob $? '
function noglob {
	[[ $2 == \[\[ ]]&& return $1 # handle nested noglobs
	local undo_noglob=$1; shift
	( "$@" )
	typeset -i e=$?
	((undo_noglob))&& set +f
	return $e
}
# ====================================================== END: NOGLOB ===

alias p='_p $# "$@"'
alias pass=' pass' # don't put in history
alias prn="/usr/bin/printf '  \e[35m｢\e[39m%s\e[35m｣\e[39m\n'"
[[ -x /usr/local/bin/rlwrap ]]&&
	alias rlwrap='rlwrap '

[[ -n $KDOTDIR ]]&& {
	KCOMPLETE=$KU/C
	: run in sub-shell for exceptions sake; (
		wantRelease=true
		makeout=$KCOMPLETE/make.out
		get-exclusive-lock -no-wait completion-make || {
			wantRelease=false
			warn 'using old completions'
			return # from subshell
		  }
		make -k -C $KCOMPLETE >$KCOMPLETE/make.out
		[[ -s $makeout ]]&& {
			notify 'Recompiled completion modules:'
			COLUMNS=${COLUMNS:-$(tput col 2>/dev/null)}
			column ${COLUMNS:+-c $((COLUMNS-8))} $makeout |
				expand| sed -e 's/^/    /'
		  }
		rm $makeout
		$wantRelease &&
			release-exclusive-lock completion-make
	)
	. $KCOMPLETE/completions.ksh
  }

export RC_HAS_RUN=true
# fin
