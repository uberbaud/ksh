#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2023-12-28,01.14.17z/2e072a5>

# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^Ufrom commit^u^]
	         Fetch updates from the ^Bgit^b upstream into the local repository, then
	         merge those updates into the local ^Bgot worktree^b.
	           ^Ufrom commit^u  Get changes for the ^Bgot worktree^b from branch/tag/commit.
	                        The default commit is the ^Iupstream current^i branch.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
warnOrDie=die
while getopts ':h' Option; do
	case $Option in
		h)	usage;															;;
		f)	warnOrDie=warn;													;;
		\?)	die USAGE "Invalid option: ^B-$OPTARG^b.";						;;
		\:)	die USAGE "Option ^B-$OPTARG^b requires an argument.";			;;
		*)	bad-programmer "No getopts action defined for ^T-$Option^t.";	;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
function doit { # {{{1
	h3 "$*"
	"$@" || die "Could not ^T$*^t"
} # }}}1
function expect { # {{{1
	[[ ${1:?} == *$2* ]]||
		die '^Tgot info^t output has changed!' "expected ^V$2^v, got ^V$1^v."
} # }}}1
function get-got-info { #{{{1
	local IFS=$NL
	set -A ${1:?} -- $(got info)
} # }}}1
function main { # {{{1
	local repo from_commit branch before after

	get-got-info info || return
	expect "${info[0]}" tree:
	expect "${info[1]}" base		&& before=${info[1]#*: }
	expect "${info[2]}" prefix
	expect "${info[3]}" branch		&& branch=${info[3]#*: }
	expect "${info[4]}" UUID
	expect "${info[5]}" repository:	&& repo=${info[5]#*: }

	doit git								\
		-C "$repo"							\
		fetch								\
			--all --tags					\
			--prune --prune-tags --force	\
			--progress						\
	|| warnOrDie "^Tgit^t did not complete. (^E$?^e)"

	from_commit=${1:-$(git -C "$repo" branch|awk '/\*/{print $2}')}

	#doit got integrate "$from_commit"  # only allows one integration
	#doit got rebase "$from_commit"     # changes branch to $from_commit
	doit got merge "$from_commit"

	# Check whether the base commit changed
	get-got-info info || die "Weirdness!"
	after=${info[1]#*: }

	notify "Base Commits" "before: $before" "after:  $after"
	[[ $before != $after ]]
} #}}}1

NL='
' # capture a newline

main "$@"; exit

# Copyright (C) 2023 by Tom Davis <tom@greyshirt.net>.
