#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2023-12-27,22.40.47z/5861ee1>

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
	         Clones a remote repo into a bare repository using ^Tgit^t and makes
			 a local ^Tgot^t checkout of that repository.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
while getopts ':h' Option; do
	case $Option in
		h)	usage;															;;
		\?)	die USAGE "Invalid option: ^B-$OPTARG^b.";						;;
		\:)	die USAGE "Option ^B-$OPTARG^b requires an argument.";			;;
		*)	bad-programmer "No getopts action defined for ^T-$Option^t.";	;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
function main { # {{{1
	NOT-IMPLEMENTED
} #}}}1

#--------8<------------------8<------------------8<--------
# print -r "  WORKTREE_PATH=${WORKTREE_PATH-}"
# print -r "  REPOSITORY_PATH=${REPOSITORY_PATH-}"
# [[ -n ${WORKTREE_PATH-} ]]&&
#     needs-cd -or-warn -with-notice "$WORKTREE_PATH"
#-------->8------------------>8------------------>8--------

needs NOT-IMPLEMENTED
main "$@"; exit

# Copyright (C) 2023 by Tom Davis <tom@greyshirt.net>.
