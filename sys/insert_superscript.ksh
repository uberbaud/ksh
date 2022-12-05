#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2021-12-08,02.36.59z/2e870ad>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Integer to Superscript
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
function transdigits { # {{{1
	sed -E \
		-e 's/0/⁰/g'	\
		-e 's/1/¹/g'	\
		-e 's/2/²/g'	\
		-e 's/3/³/g'	\
		-e 's/4/⁴/g'	\
		-e 's/5/⁵/g'	\
		-e 's/6/⁶/g'	\
		-e 's/7/⁷/g'	\
		-e 's/8/⁸/g'	\
		-e 's/9/⁹/g'
} # }}}1

cat <<-===
	CREATE TABLE superscripts (
	    i   integer NOT NULL PRIMARY KEY,
	    s   text    NOT NULL
	);
===

i=1;
while ((i<=199)); do
	s=$(print $i | transdigits)
	print -- "INSERT INTO superscripts (i,s) VALUES ($i,'$s');"
	((i++))
done

# Copyright (C) 2021 by Tom Davis <tom@greyshirt.net>.
