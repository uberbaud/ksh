#!/bin/ksh
# <@(#)tag:tw.lukas.uberbaud.foo,2025-12-03,02.23.58z/2ffe13a>
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
	         Print simple color and attribute examples.
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
	local i
	set -A a
	a[0]=normal
	a[1]=bold
	a[2]=dim
	a[3]=italic
	a[4]=underline
	a[5]=slow-blink
	a[6]=fast-blink
	a[7]=reverse
	a[8]=conceal
	a[9]=struck
	a[21]=2x-ulined
	a[51]=framed
	a[52]=encircled
	a[53]=overlined
	a[58]=clr-ulined
	# ======================================== begin show attributes ===
	#     '....+....1....+....2....+....3....+....4....+....5....
	print '\033[44;2;33m   -: attribute      2;3-  3-   9-      4-    10-\033[K\033[0m'
	typeset -R3 num
	typeset -L10 name
	for i in 0 1 2 3 4 5 6 7; do
		num=$i
		name=${a[i]}
		print -- " $num: \\033[${i}m $name \\033[0m  "	\
			"\\033[3$i;2m DIM"							\
			"\\033[22mFORE"								\
			"\\033[9${i}mBRITE"							\
			"\\033[0m "									\
			"\\033[4${i}m BACK"							\
			"\\033[10${i}m BRITE"						\
			'\033[0m'
	done
	FMT=' %3d: \e[%dm %-10s \e[0m\n'
	for i in 8 9 21 51 52 53; do
		printf "$FMT" $i $i "${a[i]}"
	done
	FMT=' %3d: \e[4;%d;5;12m %-10s \e[0m\n'
	i=58
	printf "$FMT" $i $i "${a[i]}"
	# ========================================== end show attributes ===

	print '  \033[47;30m   Note: E[8m is hidden text\033[0m'
} #}}}1

main "$@"; exit

# Copyright (C) 2025 by Tom Davis <tom@greyshirt.net>.
