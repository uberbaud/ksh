#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2021-10-26,18.46.02z/4065948>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

TRAPSIGS='EXIT HUP INT QUIT TRAP BUS TERM'

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         ^Tclone^ts a bare repository, checks that out as a worktree.
	         The repository will be in ^SGIT_BARE_REPOS^s/^Uhost/and/path/repo.git^u

	         ^GNote:^g ^T$PGM^t ^Goutputs the repository and worktree paths as^g
	                  ^Gthe variables^g ^SWORKTREE_PATH^s ^Gand^g ^SREPOSITORY_PATH^s
	                  ^Gin a form that can be^g ^Teval^t^Ged by the shell.^g
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
function bad_programmer {	# {{{2
	die 'Programmer error:'	\
		"  No getopts action defined for [1m-$1[22m."
  };	# }}}2
while getopts ':h' Option; do
	case $Option in
		h)	usage;												;;
		\?)	die "Invalid option: ^B-$OPTARG^b.";				;;
		\:)	die "Option ^B-$OPTARG^b requires an argument.";	;;
		*)	bad_programmer "$Option";							;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
function show_var { #{{{1
	local vname=$1 val
	eval val=\$$vname
	shquote "$val"
	print -r -- "$vname='$REPLY'"
} # }}}1
function clean-up { # {{{1
	local i dword
	remove_on_die-is-empty && return

	if [[ ${#remove_on_die[*]} -eq 1 ]]; then
		dword=directory
	else
		dword=directories
	fi

	warn 'Use'
	i=${#remove_on_die[*]}
	while ((i--)); do
		print -- "                 ^T${remove_on_die[i]}^T"
	done | sparkle >&2
	print -u2 -- "          to remove the added but unused $dword."
} # }}}1
function main { # {{{1
	local R repo repo_base newdir
	repo=$1
	newdir=$2

	# git worktree directory
	WORKTREE_PATH=$PWD/$newdir
	[[ -d $WORKTREE_PATH ]]|| {
		needs-path -or-die "$WORKTREE_PATH"
		shquote "$WORKTREE_PATH"
		+remove_on_die "rmdir $REPLY"
	  }

	# git bare repository directory
	R=${repo##@(http|https|ftp|ftps|git|ssh):*(/)}
	REPOSITORY_PATH=$GIT_BARE_REPOS/$R
	repo_base=${REPOSITORY_PATH%/*}
	[[ -d $repo_base ]]|| {
		needs-path -or-die "$repo_base"
		shquote "$repo_base"
		+remove_on_die "rmdir $repo_base"
	  }

	needs-cd -or-die "$repo_base"

	R="${R##*/}"
	command git clone --bare "$repo" "$R" >&2 ||
		die "^Tgit clone --bare^t ^B$repo^b"
	shquote "$REPOSITORY_PATH"
	+remove_on_die "rm -rf $REPLY"

	needs-cd -or-die "$R"
	command git worktree add "$WORKTREE_PATH" -b "$HOST" >&2 ||
		die '^Tgit worktree add ^O$^o^VWORKTREE_PATH^v ^T-b^t ^O$^o^VHOST^v' \
			"WORKTREE_PATH=^S${WORKTREE_PATH-}^s" "HOST=^S${HOST-}^s"

	trap - $TRAPSIGS
	show_var WORKTREE_PATH
	show_var REPOSITORY_PATH

} # }}}1

needs needs-path needs-cd new-array shquote

(($#<=4))||	die 'Can only handle simple clone commands.'

[[ $1 == clone ]]||	die 'Expected sub-command to be ^Tclone^t.'

[[ $2 == @(http|https|ftp|ftps|git|ssh):* ]]||
	die "Parameter does not appear to be a REPOSITORY_PATH name."
repo=$2

if [[ -n ${3-} ]]; then
	newdir=$3
else
	newdir=${repo##*/}
	newdir=${newdir%.git}
fi

new-array remove_on_die
trap clean-up $TRAPSIGS

main "$repo" "$newdir"; exit

# Copyright (C) 2021 by Tom Davis <tom@greyshirt.net>.
