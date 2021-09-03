#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-08-09:tw/02.36.22z/54749b1>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t
	         Tries to sanely update from git remotes.
	         1. ^Tgit checkout master^t if not on master,
	         2. ^Tgit pull^t or ^Tgit submodule update --remote^t,
	         3. ^Tgit checkout^t ^Uprevious^u if needed, and finally
	         4. ^Tgit merge master^t.
	       ^T${PGM} -h^t
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
		h)	usage;													;;
		\?)	die "Invalid option: [1m-$OPTARG[22m.";				;;
		\:)	die "Option [1m-$OPTARG[22m requires an argument.";	;;
		*)	bad_programmer "$Option";								;;
	esac
done
# remove already processed arguments
shift $(($OPTIND - 1))
# ready to process non '-' prefixed arguments
# /options }}}1
function get-local-to-remote-branch { # {{{1
	local found remote master
	# git-remote-links outputs "%(local)\t%(upstream)\n"*, so two (2) words
	# per local-to-remote-branch
	set -- $(git-remote-links)
	# prefer master if available, otherwise balk
	if (($#>2)); then
		found=false
		while (($#)); do
			master=$1; remote=$2; shift 2
			[[ $master == master ]]&&	{ found=true; break; }
			[[ $remote == */master ]]&&	{ found=true; break; }
		done
		$found || {
			IFS="$NL"
			warn 'Multiple local-to-remote branches found:' $(git-remote-links)
			master=
		  }
	else
		master=$1
	fi
	print -r -- "$master"
	[[ -n $master ]]
} # }}}1
function are-we-in-a-git-repository { # {{{
	InGit=$(git rev-parse --is-inside-work-tree 2>/dev/null)
	[[ $InGit == true ]]
} # }}}1
function git-current-branch { # {{{1
	command git rev-parse --abbrev-ref HEAD 2>/dev/null
} # }}}1
function git-current-ref { #{{{1
	command git describe --always --dirty
} # }}}1
function git-top-level { #{{{1
	command git rev-parse --show-toplevel 2>/dev/null
} # }}}1
function GIT { notify "git $*"; command git "$@"; }
NL='
' # capture a newline

needs git i-can-haz-inet git-remote-links

i-can-haz-inet					 || die 'No internet' "$REPLY"
are-we-in-a-git-repository		 || die 'Not a ^BGIT^b repository.'
worktree="$(git-top-level)"		 || die 'Could not resolve work tree.'
builtin cd "$worktree"			 || die "Could not ^Tcd^t to ^B$worktree^b."

master=$(get-local-to-remote-branch) ||
									die 'Cannot resolve link branch.'
branch=$(git-current-branch)
[[ $branch == $master ]]|| {
	GIT checkout "$master"		 || die "Could not ^Tcheckout^t ^B$master^b."
  }

before="$(git-current-ref)"
[[ -f .gitmodules ]]&& GIT submodule update --remote
GIT pull || die "Couldn't ^Tpull^t."
after="$(git-current-ref)"

[[ $branch == $master ]]&& {
	warn "On branch ^B$master^b (MAIN BRANCH)."
	exit 0
  }

GIT checkout $branch
[[ $before == "$after" ]]&& {
	warn 'Unchanged, quitting.'
	exit 1
  }
GIT merge "$master"

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
