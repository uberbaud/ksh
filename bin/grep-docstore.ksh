#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2018-01-27:tw/19.38.04z/32d5e9a>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^Upattern^u
	         List files matching awk style ^Upattern^u
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

needs awk zcat

(($#))||	die 'Missing required argument ^Upattern^u'
(($#==1))||	die 'Too many arguments, expected one (1): ^Upattern^u.'
cd ~/hold/DOCSTORE || die 'Could not ^Tcd^t to ^BDOCSTORE^b.'

AWKPGM="$(cat)" <<-\
	===AWKPGM===
	NR == 1	{ f=\$0; next }
	/$1/	{ print f }
	===AWKPGM===

desparkle "$AWKPGM"
splitstr NL "$REPLY" dAWKPGM

#   ↓ newline
NL='
' # ↑ newline
function only-files {(
	IFS="$NL"
	while read -r F; do
		[[ -f $F ]]|| continue
		print -r -- "$F"
	done
)}

function zgrep-docstore {
	for f in *; do
		[[ -f $f ]]|| continue
		zcat "$f" | awk "$AWKPGM" ||
			die '^Bzcat^b or ^Bawk^b' "${dAWKPGM[@]}"
	done
}

zgrep-docstore | only-files | sort | uniq; exit

# Copyright (C) 2018 by Tom Davis <tom@greyshirt.net>.
