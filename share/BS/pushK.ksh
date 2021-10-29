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
	[[ $hlevel == [12] ]]||
		die "GIT parameter #2 is not a level indicator" "^S$lnum^s: ^U$*^u"
	for o; do
		[[ $o == msg ]]&& break
		cmd="${cmd:+$cmd }$1"
		shift
	done
	h1 "$cmd"
	git $cmd || die "${2:-^B$cmd^b}"
} # }}}1

(($#))&& die 'Unexpected arguments. Expected ^Bnone^b.'

needs git h1 i-can-haz-inet needs-cd

i-can-haz-inet	|| die 'No internet' "$REPLY"
needs-cd -or-die "${KDOTDIR:?}"

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
[[ $branch == trunk ]]&& die 'On branch ^Etrunk^e!!!'

function commit-everything {
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
}

commit-everything $HOST
GIT 1 checkout trunk --quiet
GIT 1 merge $HOST --quiet
commit-everything trunk
GIT 1 push
GIT 1 checkout $HOST --quiet

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
