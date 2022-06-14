#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2022-06-08,20.04.58z/1d2aa2>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

PROMPT='  > '

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-p^t ^Uprompt^u^] ^Uout file^u
	         ^Tcat^ts text to ^Uout file^u.
	           ^T-p^t  Use ^Uprompt^u instead of ^[^T$PROMPT^t^].
	         Exits on ^S^^D^s or ^T.^t on a line by itself.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
while getopts ':np:h' Option; do
	case $Option in
		n)  exit 0;															;;
		p)  PROMPT=$OPTARG;													;;
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
(($#))||	die 'Missing required ^Ufilename^u for output.'
(($#>1))&&	die 'Too many parameters. Only output ^Ufilename^u expected.'

notify 'Use ^T.^t or ^S^^D^s to exit.'
while IFS= read ln"?$PROMPT"; do
	[[ $ln == . ]]&& break
	print -r -- "$ln"
done >$1; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
