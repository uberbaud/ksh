#!/bin/ksh
# @(#)[:YOZB9_2>K`*GnZkFMldR: 2017-11-20 19:26:21 Z tw@csongor]
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         List all notes for a directory.
	       ^T$PGM -h^t
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

needs awk less sparkle

[[ -d NOTES ]]|| exit 0		#empty
cd NOTES || die 'Could not ^Tcd^t into ^BNOTES^b.'

set -A notes -- $(/bin/ls *.note 2>/dev/null|sort -n)
((${#notes[*]}))|| exit 0	#empty

AWKPGM="$(cat)" <<-\
	\===AWK===
		/@\(#\)\[/ {next}
		FNR == 2 && /^[0-9][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9].* Z/ {
				if (FNR != NR) { print "" }
				print "^B"$0"^b"
				next
			}
		# always
			{print}
	===AWK===

awk "$AWKPGM" "${notes[@]}"|sparkle|less -iMSx4 -FXc; exit

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
