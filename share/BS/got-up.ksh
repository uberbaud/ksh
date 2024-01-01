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
function doit { # {{{1
	h3 "$*"
	"$@" || die "Could not ^T$*^t"
} # }}}1
function main { # {{{1
	local repo IFS=$IFS O
	O=$IFS
	IFS=$NL
	set -- $(got info) || return
	IFS=$O
	for info; do
		[[ $info == repository:* ]]|| continue
		repo=${info#repository: }
	done
	doit git -C "$repo" fetch --all
	doit got update
} #}}}1

NL='
' # capture a newline

main "$@"; exit

# Copyright (C) 2023 by Tom Davis <tom@greyshirt.net>.
