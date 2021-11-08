#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-08-09:tw/02.36.22z/54749b1>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

REPODIR=$XDG_DATA_HOME/repos
# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t
	         Tries to sanely update from git remotes.
	         1. ^Tgit checkout^t ^Strunk^s if not on ^Strunk^s,
	         2. ^Tgit pull^t or ^Tgit submodule update --remote^t,
	         3. ^Tgit checkout^t ^Uprevious^u if needed, and finally
	         4. ^Tgit merge^t ^Strunk^s.
	       ^T${PGM} -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}1
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
	local found remote branch
	# git-remote-links outputs "%(local)\t%(upstream)\n"*, so two (2) words
	# per local-to-remote-branch
	set -- $(git-remote-links)
	# prefer trunk if available, otherwise balk
	if (($#>2)); then
		found=false
		while (($#)); do
			branch=$1; remote=$2; shift 2
			[[ $branch == @(main|master|trunk) ]]&&		{ found=true; break; }
			[[ $remote == */@(main|master|trunk) ]]&&	{ found=true; break; }
		done
		$found || {
			IFS="$NL"
			warn 'Multiple local-to-remote branches found:' $(git-remote-links)
			branch=
		  }
	else
		branch=$1
	fi
	print -r -- "$branch"
	[[ -n $branch ]]
} # }}}1
function git-current-branch { # {{{1
	#command git rev-parse --abbrev-ref HEAD 2>/dev/null
	command git branch --show-current 2>/dev/null
} # }}}1
function git-current-ref { #{{{1
	command git describe --always --dirty
} # }}}1
function git-top-level { #{{{1
	command git rev-parse --path-format=absolute --show-toplevel 2>/dev/null
} # }}}1
function git-top-level-memoize { # {{{1
	print "${TOPLEVEL:="$(git-top-level)"}"
} # }}}1
function GIT { notify "git $*"; command git "$@"; }
function it-is-bare { # {{{1
	local bool
	bool=$(git rev-parse --is-bare-repository 2>/dev/null)
	${bool:-false}
} # }}}1
function it-is-a-linked-worktree { # {{{1
	# if it's not bare, but it is git, then the .git file
	# system object will be a file pointing to the repository.
	[[ -f $(git-top-level-memoize)/.git ]]
} # }}}1
function it-is-standard { # {{{1
	local bool
	bool=$(git rev-parse --is-inside-work-tree 2>/dev/null)
	${bool:-false}
} # }}}1
function handle-standard { # {{{1
	worktree="$(git-top-level-memoize)"		 || die 'Could not resolve work tree.'
	needs-cd -or-die "$worktree"

	trunk=$(get-local-to-remote-branch) ||
									die 'Cannot resolve link branch.'
	branch=$(git-current-branch)
	[[ $branch == $trunk ]]|| {
		GIT checkout "$trunk"		 || die "Could not ^Tcheckout^t ^B$trunk^b."
	  }

	before="$(git-current-ref)"
	[[ -f .gitmodules ]]&& GIT submodule update --remote
	GIT pull || die "Couldn't ^Tpull^t."
	after="$(git-current-ref)"

	[[ $branch == $trunk ]]&& {
		warn "On branch ^B$trunk^b (MAIN BRANCH)."
		return 0
	  }

	GIT checkout "$branch"
	[[ $before == $after ]]&& {
		warn 'Unchanged, quitting.'
		return 1
	  }
	GIT merge "$trunk"
} # }}}1
function convert-and-move-repo-to-bare { # {{{1
	local awkpgm origin basedir newrepo branch

	notify 'Converting to ^Ubare repo^u + ^Uworkingdir^u.'

	awkpgm='/^origin\t[^[:space:]]+ \(fetch\)$/ {print $2}'
	origin=$(git remote -v|awk "$awkpgm")
	[[ -n origin ]]|| die 'Could not get ^Sorigin^s for this ^Brepo^b.'

	origin=${origin##+([a-z]):+(/)} # remove schema and any prefix '/'s
	newrepo=${origin##*/}		# just the last bit
	basedir=${origin%/"$newrepo"}
	[[ -n basedir ]]||
		die "^Sorigin^s isn't in an expected format." "$origin"
	basedir=$REPODIR/$basedir

	needs-path -or-die "$basedir"

	newrepo=$basedir/${newrepo%.git}.git

	mv "$REPO" "$newrepo" || die "Could not ^Tmv^t ^S.git^s"

	# mark it bare
	git -C "$newrepo" config --bool core.bare true

	# remove / ¿convert branches to worktrees?
	set -- $(git config --local --list|awk -F\\. '/^branch\./ {print $2}'|uniq)
	for branch; do
		# keep 
	done

	# add 

} # }}}1


[[ -d $REPODIR ]]|| die "No such directory: ^B$REPODIR^b."

needs git i-can-haz-inet git-remote-links needs-cd needs-path

NL='
' # capture a newline

i-can-haz-inet || die 'No internet' "$REPLY"

REPO=$(git rev-parse --path-format=absolute --git-common-dir) ||
	die 'Not a ^Sgit^b repository.'

if it-is-bare; then
	GIT fetch --all
elif it-is-a-linked-worktree; then
	GIT -C "$REPO" fetch --all	# -C SHOULD NOT be necessary, but it's userdoc
	GIT pull
elif it-is-standard; then
	# TODO: mv .git $REPODIR/$basename.git                          #
    #       barify $REPODIR/$basename.git                           #
	#       print -r -- "$WORKTREE_SKELETON" >.git                  #
    #       add-this-dir-as-worktree                                #
	#       GIT -C "$REPO" fetch --all                              #
	#       GIT merge origin                                        #
	handle-standard
else
	die 'Supposedly a git repository, but of an unknown type. Not:' \
		'^Bstandard^b' '^Bbare^b' '^Bworktree^b'
fi

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
