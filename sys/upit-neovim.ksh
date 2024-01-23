#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2022-01-02,21.18.17z/34f21aa>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

fLOG=~/log/neovim-upit.log

# save all output
[[ ${1:-} == @(SCRIPTED|-h|help) ]]|| { # {{{1
	needs h{1,2} i-can-haz-inet script yes-or-no

	i-can-haz-inet || die "$REPLY"
	export fTEMP=$(mktemp)
	#====================================================== BEGIN: BIG JOB ===
	script -c "$0 SCRIPTED $*" "$fLOG"
	#====================================================== END:   BIG JOB ===
	rc=$(<$fTEMP); rm -f "$fTEMP"; ((rc))&& exit $rc

	yes-or-no 'Run check health on new build' &&
		nvim +checkhealth

	exit 0
  } # }}}1
[[ $1 == SCRIPTED ]]&& shift # remove SCRIPTED

: ${XDG_DATA_HOME:?} ${LOCALBIN:?}
localPrefix=${XDG_DATA_HOME%/share}/nvim
NL='
'
# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle-path "$localPrefix"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-c^t^|^Tclean^t^] ^[^T-f^t^]
	         Do all the updating bits.
	           ^T-c^t^|^Tclean^t  Clean $REPLY.
	           ^T-k^t^|^Tkeep^t   Keep previous build files.
	           ^T-f^t        Force new build.
	       ^T$PGM -h^t^|^Thelp^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
needs die
want_clean_build=true
want_clean_install=false
FORCE=false
while (($#)); do
	case $1 in
		-c|clean)	want_clean_install=true;		;;
		-k|keep)	want_clean_build=false;			;;
		-h|help)	usage;							;;
		-f)			FORCE=true;						;;
		-*)			die "Unknown flag ^T$1^t";		;;
		*)			die "Unknown command ^T$1^t";	;;
	esac
	shift
done
# /options }}}1
function main { # {{{1
	h1 'Get neovim updates'
	needs-cd -or-die -with-notice "$NVIM_SRC_PATH"
	got-up nightly || $FORCE || {
		warn 'No changes to worktree, exiting.' 'Use ^T-f^t to force a rebuild.'
		return
	  }

	sparkle-path "$NVIM_SRC_PATH"
	spSrcPath=$REPLY

	$want_clean_build && {
		h1 'Cleaning previous build objects'
		make distclean
	  }

	h1 'Make neovim (nvim)'
	G=$NVIM_SRC_PATH/.git
	[[ -e $G ]]|| {
		N=neovim
		print "gitdir: ${REPOS_HOME:?}/github.com/$N/$N.git/worktrees/$N" >$G
		trap "rm '$G'" EXIT
	  }
	make CMAKE_BUILD_TYPE=$build CMAKE_INSTALL_PREFIX="$localPrefix" ||
		die "Could not make $spSrcPath."

	$want_clean_install && {
		[[ $localPrefix == $HOME/* ]]||
			die '^O$^o^VlocalPrefix^v is not local' "$localPrefix"
		h1 "Cleaning $localPrefix"
		rm -rf "$localPrefix"
	  }

	h1 "Install neovim (nvim) to $localPrefix"
	make install ||
		die "Could not install $spSrcPath."

	h1 'Link nvim bits into LOCALBIN, etc'
	needs-cd -with-notice -or-die "$localPrefix"
	link-nvim-to-locals bin "$LOCALBIN"
	link-nvim-to-locals man "$XDG_DATA_HOME/man"

	h1 'Update all the pluggins'
	needs-cd -with-notice -or-die "$NVIM_PLUGINS_PATH"
	upit */

	h1 'Update Tree-Sitter grammars'
	#notify 'running ^Tnvim +^BTSInstallSync^b^t'
	#$LOCALBIN/nvim -i NONE --headless +'TSInstallSync all' +quit
	notify 'running ^Tnvim +^BTSUpdateSync^b^t'
	$LOCALBIN/nvim -i NONE --headless +TSUpdateSync +quit
	print

	h1 Done
	sparkle-path "$fLOG"
	notify "Output was saved to $REPLY"
} # }}}1

needs as-root got-up needs-cd needs-path notify sparkle-path upit

build=Release
CC=clang
CPP=clang-cpp
CXX=clang-cpp
export CFLAGS=-fPIC
unset LDFLAGS LDLIBS

LOCAL_GNUTOOLS_PATH=$XDG_DATA_HOME/gnu-tools
needs-path -or-die "$LOCAL_GNUTOOLS_PATH"
PATH=$LOCAL_GNUTOOLS_PATH:$PATH
needs-file -or-die "$LOCAL_GNUTOOLS_PATH/make"

NVIM_SRC_PATH=$HOME/src/textmunge/NeoVIM/neovim
# NVIM_SRC_PATH=$HOME/src/textmunge/NeoVIM/neo-neo
needs-path -or-die "$NVIM_SRC_PATH"

if [[ -e $NVIM_SRC_PATH/.git ]]; then
	: # we already 'need'ed git
elif [[ -e $NVIM_SRC_PATH/.got ]]; then
	needs got
else
	sparkle-path "$NVIM_SRC_PATH"
	die "$REPLY is neither a ^Bgit^b nor a ^Bgot^b repository."
fi

NVIM_PLUGINS_PATH=$XDG_DATA_HOME/nvim/site/pack/v/start
needs-path -create -with-notice -or-die "$NVIM_PLUGINS_PATH"

main "$@"; print -- "$?" >$fTEMP; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
