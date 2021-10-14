# <@(#)tag:csongor.greyshirt.net,2017-04-20:tw/19.11.47z/4e02e72>
# ksh profile
# vim: ts=4 ft=ksh

RC_HAS_RUN=true
# we are NOT sourcing /etc/ksh.kshrc because it does way too much stuff we 
# don't need. But these come from there.
export SHORTPATH=${SHORTPATH:-$PATH}
export UID=${UID:-$(id -u)}
export USER=${USER:-$(id -un)}
export LOGNAME=$USER
export HOME="$(getent passwd $USER | awk -F: '{print $6}')"
TTY="${TTY:-$(basename "$(tty)")}"
export HOSTNAME=${HOSTNAME:-$(uname -n)}
export HOST=${HOSTNAME%%.*}
export TERM

export SYSLOCAL=/usr/local
export URI_AUTHORITY='greyshirt.net'

# parse ENV to find out where we are
[[ -d "${ENV%/*}" ]]&& KDOTDIR="${ENV%/*}"
export KDOTDIR

# XDG paths
if [[ -d ${XDG_CONFIG_HOME:-~/config} ]]; then
	XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-~/config}
	if [[ -f $XDG_CONFIG_HOME/user-dirs.dirs ]]; then
		. $XDG_CONFIG_HOME/user-dirs.dirs
	fi
	for v in $(typeset +); do [[ $v == XDG_* ]]&& export $v; done

	[[ -z $KDOTDIR && -d $XDG_CONFIG_HOME/ksh ]]&&
		KDOTDIR=$XDG_CONFIG_HOME/ksh

else
	XDG_CONFIG_HOME=$HOME/config
	XDG_DATA_HOME=$HOME/local
	XDG_CACHE_HOME=$HOME/local/cache

	[[ -d $XDG_CONFIG_HOME ]]|| mkdir -p $XDG_CONFIG_HOME
	[[ -d $XDG_DATA_HOME   ]]|| mkdir -p $XDG_DATA_HOME
	[[ -d $XDG_CACHE_HOME  ]]|| mkdir -p $XDG_CACHE_HOME
fi
xdgdata=$XDG_DATA_HOME
xdgcfg=$XDG_CONFIG_HOME
xdgcache=$XDG_CACHE_HOME
SYSDATA=$xdgdata/sysdata
[[ -d $SYSDATA ]]&& export SYSDATA || unset SYSDATA

[[ -n $KDOTDIR ]]&& {
	
	K=$KDOTDIR;			KU=$KDOTDIR/$HOST;		KS=$KDOTDIR/share
						F=$KU/F;				FS=$KS/FS
						B=$KU/B					BS=$KS/BS
												H=$KS/HS

	[[ -d $KU ]]|| mkdir $KU
	export FPATH=$F
	KHIST=$KU/history
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
		awk '/^$histmark\$/{p=1;next}p' "\$fhist">>"\$KHIST"
		(($?))&& { warn 'Did not update \$K/H/history'; return; }
		rm "\$fhist"
	}
	===
	eval "$T"
	add-exit-action ShHistCleanUp
	tail -n 127 $KHIST>$fhist
	print "$histmark" >>$fhist
	HISTFILE="$fhist"
fi

# paths
export HISTCONTROL=ignoredups:ignorespace
export HISTFILE=$fhist
export HISTSIZE=8191
#export USR_C_BASE=$xdgdata/c
#export LD_LIBRARY_PATH=$USR_C_BASE/lib
#export USR_CLIB=$USR_C_BASE/lib
#export USR_INCL=$USR_C_BASE/api
export LOCALBIN=$xdgdata/bin
# LUA wants SEMICOLON separated PATTERNS, empty item is default
export LUA_PATH_5_3="$xdgdata/lua/5.3/?.lua;$xdgdata/lua/5.3/?/init.lua;;"
export LUA_CPATH_5_3="$xdgdata/lua/5.3/?.so;;"
export CARGO_HOME=$xdgcfg/cargo
export TEMPLATES_FOLDER=$xdgdata/templates
export TMPDIR=$xdgcache/temp
export USRBIN=$HOME/bin/ksh
export PERL_UNICODE=AS
export PERLDOC='-MPod::Perldoc::ToTerm'
export PERLDOC_SRC_PAGER=$VISUAL
export PSQLRC=$xdgcfg/pg/psqlrc

# have cpanm install things where we want them
export USR_PLIB=$xdgdata/lib/perl5
export PERL5LIB=$USR_PLIB
# ^ add? -> # ${PERLBREW_LIB:+:$PERLBREW_LIB}
export PERLBREW_BIN=$PERLBREW_CURRENT/bin
export PERL_MB_OPT="--install_base $USR_PLIB"
export PERL_MM_OPT="INSTALL_BASE=$USR_PLIB"


####### SET PATH
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
wantpath "$PERLBREW_BIN"		PREPEND
wantpath "$MMH_BIN_PATH"		PREPEND
wantpath "$LOCALBIN"			PREPEND
wantpath "$HOME"/bin			PREPEND
wantpath "$USRBIN"				PREPEND
# APPEND, so in order
wantpath /usr/games				APPEND
wantpath "$PERLBREW_ROOT/bin"	APPEND
wantpath "$JDK_PATH"			APPEND
wantpath $ROFFTOOLS_PATH		APPEND

# input, locale, and such
set -o vi -o vi-tabcomplete
set -o braceexpand -o ignoreeof -o physical

export INPUTRC=$xdgcfg/init/input.rc
[[ -n ${LC_CTYPE:-} ]]&& {
	export LANG=$LC_CTYPE
	for v in ALL COLLATE MESSAGES MONETARY NUMERIC TIME; do
		export LC_$v=$LANG
	done
  }

# init files and paths
export BC_ENV_ARG=$xdgcfg/etc/bc.rc
export BZR_HOME=$xdgcfg/bzr
export HGRCPATH=$xdgcfg/hg

# ==== DEFAULT APPS
# handle whether  EDITOR or VISUAL was set in $HOST.kshrc
[[ -z ${VISUAL:-${EDITOR:-}} ]]&& {
	L=/usr/local/bin; S=/usr/bin; U=$HOME/local/bin
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
for p { for i in $p/f-*; { i="${i#$p/}"; alias "${i#f-}=$i"; } }

# FPATH functions are implicitly autoloaded, BUT the completion 
# mechanism doesn't know about them unless we explicitly autoload them
for p { for i in $p/*; { typeset -fu "${i##*/}"; } }

# clean up
unset o p i
set --
############[ END FPATH SPECIALNESS ]#####################################

alias cd='_u="$-"; set -u; f-cd'
alias cls='clear colorls $LS_OPTIONS'
alias clear='f-clear '
alias doas='as-root '
alias hush='>/dev/null 2>&1 '
alias k='fc -s'
if [[ -x /usr/local/bin/colorls ]]; then
	alias ls='/usr/local/bin/colorls $LS_OPTIONS'
else
	alias ls='/bin/ls $LS_OPTIONS'
fi
alias no2='2>/dev/null '
alias noerr='2>/dev/null '
alias noglob='set -f;noglob '; function noglob { set +f; ("$@"); }
alias prn="printf '  \e[35m｢\e[39m%s\e[35m｣\e[39m\n'"

[[ -n $KDOTDIR ]]&& {
	KCOMPLETE=$KU/C
	: run in sub-shell for exceptions sake; (
		wantRelease=true
		makeout=$KCOMPLETE/make.out
		get-exclusive-lock-or-exit completion-make || {
			wantRelease=false
			warn 'using old completions'
		  }
		make -k -C $KCOMPLETE >$KCOMPLETE/make.out
		[[ -s $makeout ]]&& {
			notify 'Recompiled completion modules:'
			COLUMNS=${COLUMNS:-$(tput col)}
			column -c $((COLUMNS-8)) $makeout|expand|sed -e 's/^/    /'
		  }
		rm $makeout
		$wantRelease &&
			release-exclusive-lock completion-make
	)
	. $KCOMPLETE/completions.ksh
  }

# fin
