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
function warnOrDie { #{{{1
	case $warnOrDie in
		die)  die "$@" 'Use [1m-f22m to force an edit.';		;;
		warn) warn "$@";											;;
		*)    die '[1mProgrammer error[22m:' \
					'warnOrDie is [1m${warnOrDie}[22m.';		;;
	esac
} # }}}1
function _GIT { # {{{1
	local cmd= o hlevel lnum
	lnum=$1
	hlevel=$2
	shift 2
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
alias GIT='_GIT $LINENO'

(($#))&& die 'Unexpected arguments. Expected ^Bnone^b.'

needs git h1 i-can-haz-inet

i-can-haz-inet	|| die 'No internet' "$REPLY"
cd ${KDOTDIR:?}	|| die 'Could not ^Tcd^t to ^S$KDOTDIR^s.'

alias FAIL='{ warn "FAILED"; exit 1; }'

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
[[ $branch == master ]]&& die 'On branch ^Emaster^e!!!'

function commit-everything {
	h1 "Committing on ^S$1^s"
	# add untracked and unignored files, if any
	set -- $(git ls-files --exclude-standard --others)
	(($#))&&
		GIT 2 add "$@"

	# check for unstaged changes in the working tree
	git diff-files --quiet ||
		GIT 2 add --all

	# check for uncommitted changes in the index
	git diff-index --cached --quiet HEAD ||
		GIT 2 commit -av	 msg "did not commit ^B$1^b"
}

commit-everything $HOST
GIT 1 checkout master --quiet
GIT 1 merge $HOST --quiet
commit-everything master
GIT 1 push
GIT 1 checkout $HOST --quiet

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
