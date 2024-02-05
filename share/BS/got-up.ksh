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
	^F{4}Usage^f: ^T$PGM^t ^[^Uref name^u^]
	         Fetch updates from the ^Bgit^b upstream into the local repository, then
	         merge those updates into the local ^Bgot worktree^b.
	           ^Uref name^u  Update the ^Bgot worktree^b to match a given ^Bbranch^b or ^Btag^b.
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
function latest-git-ref { # {{{1
	local trunk ref_prefix
	needs-cd -or-die "${2:?}"
	[[ -f HEAD ]]|| ERRMSG='Bad repository format: no ^BHEAD^b.' return
	ref_prefix='ref: '
	trunk=$(<HEAD)
	[[ $trunk == $ref_prefix* ]]||
		ERRMSG="Bad HEAD format: not ^T$ref_prefix^t^O*^o." return
	trunk=${trunk#ref: }
	command git -C "$1" show-ref --head | awk "\$2 == "$trunk" {print \$1}"
} # }}}1
function main { # {{{1
	local repo upto_ref branch before after

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

	if [[ -n ${1:-} ]]; then
		upto_ref=$(git -C "$repo" show-ref "$1") || {
			desparkle "$1"
			die "^V$REPLY^v is not a valid ^Btag^b or ^Bbranch^b."
		  }
		upto_ref=${upto_ref% *}
	else
		upto_ref=$(latest-git-ref "$repo") || die "$ERRMSG"
	fi

	# return FALSE if there's no updating to do
	[[ $upto_ref != $before ]]|| return

	#----
	# *different branch
	#    ERRMSG: target commit is on a different branch
	#    requires "$upto_ref" to be on the same branch
	#----
	doit got update -c "$upto_ref"
	#doit got merge "$upto_ref"			# doesn't accept commit-ids
	#doit got update -c "$upto_ref"		# *different branch

	# Check whether the base commit changed
	get-got-info info || die "Weirdness!"
	after=${info[1]#*: }

	notify "Base Commits"	\
		"before: $before"	\
		"after:  $after"	\
		"wanted: $upto_ref"

	# return TRUE if an update occured, FALSE otherwise (SHOULD never 
	# get here with FALSE, but maybe got update failed).
	[[ $before != $after ]]
} #}}}1

NL='
' # capture a newline

main "$@"; exit

# Copyright (C) 2023 by Tom Davis <tom@greyshirt.net>.
