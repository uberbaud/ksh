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
	^F{4}Usage^f: ^T$PGM^t
	         Specially handle got/git /home/tw/local/share/repos connection.
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
function main { # {{{1
	local repo IFS=$IFS O origin branch before after
	O=$IFS
	IFS=$NL; set -- $(got info) || return; IFS=$O

	expect "$1" tree:
	expect "$2" base        && before=${2#*: }
	expect "$3" prefix
	expect "$4" branch      && branch=${4#*: }
	expect "$5" UUID
	expect "$6" repository: && repo=${6#*: }

	origin=$(git -C "$repo" branch|awk '/\*/{print $2}')
	doit git								\
		-C "$repo"							\
		fetch								\
			--all --tags					\
			--prune --prune-tags --force	\
			--progress						\
	|| warnOrDie "^Tgit^t did not complete. (^E$?^e)"

	#doit got integrate $origin # only allows one integration
	#doit got rebase $origin    # changes branch to $origin
	doit got merge $origin

	# Check whether the base commit changed
	IFS=$NL; set -- $(got info) || die "Weirdness!"; IFS=$O
	after=${2#*: }

	notify "Base Commits" "before: $before" "after:  $after"
	[[ $before != $after ]]
} #}}}1

NL='
' # capture a newline

main "$@"; exit

# Copyright (C) 2023 by Tom Davis <tom@greyshirt.net>.
