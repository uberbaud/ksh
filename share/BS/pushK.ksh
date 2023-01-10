#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-08-09:tw/02.36.22z/54749b1>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t
	         Save ^Bksh^b config to ^Bgithub.com^b.
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
function GIT { # {{{1
	local cmd= o hlevel
	hlevel=$1
	shift
	[[ $hlevel == [123] ]]||
		die "GIT parameter #2 is not a level indicator" "^S$lnum^s: ^U$*^u"
	for o; do
		[[ $o == msg ]]&& break
		cmd="${cmd:+$cmd }$1"
		shift
	done
	h$hlevel "$cmd"
	git $cmd || die "${2:-^B$cmd^b}"
} # }}}1
function git-branch-name { # {{{1
	git rev-parse --abbrev-ref HEAD 2>/dev/null && return
	sparkle-path "$PWD"
	die "$REPLY is not a ^Bgit^b repository."
} # }}}1
function commit-everything { # {{{1
	local branch
	branch=$1
	h1 "Committing on <$branch>"
	# add untracked and unignored files, if any
	set -- $(git ls-files --exclude-standard --others)
	(($#))&&
		GIT 2 add "$@"

	# check for unstaged changes in the working tree
	git diff-files --quiet ||
		GIT 2 add --all

	# check for uncommitted changes in the index
	git diff-index --cached --quiet HEAD ||
		GIT 2 commit -av	 msg "did not commit ^B$branch^b"
} # }}}1
function diffstat { # {{{1
	(($#<1))&& bad-programmer "Missing required parameter ^Ubranch^u."
	(($#>1))&& bad-programmer "Unexpected parameters. Wanted ^Ubranch^u."
	git diff --shortstat "$1"
} # }}}1
function handle-github-ssh-password { # {{{1
	local agent
	WE_STARTED_SSH_AGENT=false

	agent=${SSH_AGENT_PID:-}
	[[ -n $agent && $(ps -p $agent -ocommand=) == *ssh-agent* ]]&& return

	eval "$(ssh-agent)" 2>/dev/null || return

	WE_STARTED_SSH_AGENT=true
	AWKPGM=$(</dev/stdin) <<-\
	===AWK===
	/^Host github\.com/				{p=1;next}
	/^Host /						{p=0;next}
	/^[[:space:]]+IdentityFile/		{print $NF;exit}
	===AWK===

	fID=$(awk "$AWKPGM" ~/.ssh/config)
	ssh-add ${fID+"$fID"}
} # }}}1
function finit-github-ssh-password { # {{{1
	$WE_STARTED_SSH_AGENT &&
		ssh-agent -k >/dev/null 2>&1
} # }}}1

(($#))&& die 'Unexpected arguments. Expected ^Bnone^b.'

needs git h1 h3 i-can-haz-inet needs-cd sparkle-path message

needs-cd -or-die "${KDOTDIR:?}"

branch=$(git-branch-name)
[[ $branch == trunk ]]&& die 'On branch ^Etrunk^e!!!'
[[ $branch != $HOST ]]&& die "On branch ^E$branch^e, not branch ^E$HOST^e!!!"

#if [[ -z $(git status --short) ]]; then
DIFFSTAT=$(diffstat trunk) ||
	die "Weirdly, ^Tgit diff --shortstat trunk^t failed."
if [[ -z $DIFFSTAT ]]; then
	notify 'Nothing to commit. Exiting.'
	return
else
	message ' ^Nstatus^n:' '        ' "$DIFFSTAT"
	i-can-haz-inet	|| die 'No internet' "$REPLY"
	handle-github-ssh-password

	# save our work
	commit-everything $HOST

	# get the latest from origin
	GIT 1 fetch --all

	[[ $(git rev-parse trunk) == $(git rev-parse FETCH_HEAD) ]]|| {
		# merge trunk with origin/trunk
		GIT 1 checkout trunk --quiet
		GIT 3 merge FETCH_HEAD --quiet

		# merge newly fetched with origin/trunk (via trunk)
		GIT 1 checkout $HOST --quiet
		GIT 3 merge trunk
	  }

	# merge our work into trunk (should never have conflicts)
	GIT 1 checkout trunk --quiet
	GIT 3 merge $HOST

	# merge our work into origin (via trunk)
	GIT 3 push

	# get back to where you once belonged
	GIT 1 checkout $HOST --quiet

	# we're done with the ssh bits
	finit-github-ssh-password 
fi; exit

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
