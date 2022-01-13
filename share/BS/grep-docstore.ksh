#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2018-01-27:tw/19.38.04z/32d5e9a>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-o^t^|^T-a^t^] ^Upattern^u
	         List ^BDOCSTORE^b archived filenames whose content matches the
	         awk style ^Upattern^u. By default, only list files currently in
	         the filesystem.
	           ^T-o^t  List filenames not in the file system.
	           ^T-a^t  List all filenames (in or not in the file system).
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
ins=true; outs=false
while getopts ':aoh' Option; do
	case $Option in
		a)	ins=true; outs=true;									;;
		o)	ins=false; outs=true;									;;
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

needs awk zcat needs-cd

(($#))||	die 'Missing required argument ^Upattern^u'
(($#==1))||	die 'Too many arguments, expected one (1): ^Upattern^u.'
needs-cd -or-die ~/hold/DOCSTORE

#   ↓ newline
NL='
' # ↑ newline

AWKPGM=$(</dev/stdin) <<-\
	===AWKPGM===
	NR == 1	{ f=\$0; next }
	/$1/	{ print f; nextfile }
	===AWKPGM===

desparkle "$AWKPGM"
splitstr NL "$REPLY" dAWKPGM

function only-in-files { # {{{1
	while IFS= read -r F; do
		[[ -f $F ]]|| continue
		print -r -- "$F"
	done
} # }}}1
function only-out-files { # {{{1
	while IFS= read -r F; do
		[[ -f $F ]]&& continue
		print -r -- "$F"
	done
} # }}}1

if $ins && $outs; then
	alias only-files=cat
elif $ins; then
	alias only-files=only-in-files
elif $outs; then
	alias only-files=only-out-files
else
	die 'Bad programmer:' '^S$ins^s and ^S$outs^s are both ^Ifalse^i.'
fi

function zgrep-docstore {
	for f in *; do
		[[ -f $f ]]|| continue
		zcat "$f" | awk "$AWKPGM" ||
			die '^Bzcat^b or ^Bawk^b' "${dAWKPGM[@]}"
	done
}

zgrep-docstore | only-files | sort | uniq; exit

# Copyright (C) 2018 by Tom Davis <tom@greyshirt.net>.
