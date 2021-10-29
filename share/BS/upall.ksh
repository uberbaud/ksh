#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2018-08-11:tw/18.50.56z/3fb250b>
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
	         Find and ^Tupit^t all supported repositories.
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
		h)	usage;												;;
		\?)	die "Invalid option: ^B-$OPTARG^b.";				;;
		\:)	die "Option ^B-$OPTARG^b requires an argument.";	;;
		*)	bad_programmer "$Option";							;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1

needs upit new-array

(($#))|| set -- "$PWD"

new-array find_args
first=true
for dotf in $(upit -D); do
	$first || +find_args -o
	+find_args \( -name "$dotf" -print0 -prune \)
	first=false
done
for M in configure {GNU,}Makefile{,.ac} cmake{,.ac}; do
	+find_args \( -name "$M" -prune \)
done

# wrap script guts in a function so edits to this script file don't 
# affect running instances of the script.
function do-one {
	[[ -d $1 ]]|| {
		desparkle "$1"
		warn "^B$REPLY^b is not a directory."
		return
	  }
	find "$1" "${find_args[@]}" | xargs -0 upit
}

for d; do do-one "$d"; done; exit

# Copyright (C) 2018 by Tom Davis <tom@greyshirt.net>.
