#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2022-06-26,00.05.45z/33fb84e>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^UC Source Code^u
	         Show preprocessed ^UC Source Code^u.
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
function workit { # {{{1
	print -r -- "// preprocessed $3"
	sed -E -e "1,${2}d" -e '/^[[:space:]]*#/d' <$1
} # }}}1

needs awk cc needs-file sed

(($#))||	die 'Missing required parameter ^TC Source Code^t'
(($#>1))&&	die 'Too many parameters. Expected only ^TC Source Code^t'
needs-file -or-die "$1"

awkpgm=$(</dev/stdin) <<-\
	\===AWK===
	BEGIN {x=0}
	/^# [0-9]+ "<stdin>"/ {x=FNR}
	END {print x}
	===AWK===

tmpfile=$(mktemp) || die 'Could not ^Tmktemp^t.'
print -r -- "mktemp -> $tmpfile"
trap "rm '$tmpfile'" EXIT

cc -E "$1" >$tmpfile
delto=$(awk 'BEGIN {x=0} /^# [0-9]+ "'"$1"'"/ {x=FNR} END {print x}' <$tmpfile)
((delto))|| die "Could not find file start marker."

workit "$tmpfile" $delto "$1" |
	cat -s |
	nvim -MR +'set ft=c' -

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
