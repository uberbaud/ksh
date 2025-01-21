#!/bin/ksh
# <@(#)tag:tw.lucas.uberbaud.foo,2025-01-02,03.57.04z/1e02095>
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
	         Incorporate mail from an mbox on stdin.
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
	integer i=1

	IFS= read ln || { warn "Empty"; return; }
	[[ $ln == From\ * ]]|| die 'Not an ^Bmbox^b format file.'
	while IFS= read ln; do
		print -- "------------------------------[ $((i++)) ]---"
		while [[ $ln != From\ * ]]; do
			print -r -- "$ln"
			IFS= read ln || break
		done | rcvstore +inbox
	done

} #}}}1

needs rcvstore
main "$@"; exit

# Copyright (C) 2025 by Tom Davis <tom@greyshirt.net>.
