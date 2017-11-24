#!/bin/ksh
# @(#)[:VYCgD{-?KTQ|k?2m9&=p: 2017-08-08 03:00:12 Z tw@csongor]
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t ^Ufile name^u
	         X11 reader
	       ^T${PGM} -h^t
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

(($#))||	die 'Missing required parameter, ^Ufile name^u.'
(($#>1))&&	die 'Too many parameters. Expected one (1).'

needs xmessage
desparkle "$1"
[[ -a $1 ]]|| die "^B$REPLY^b does not exist."
[[ -f $1 ]]|| die "^B$REPLY^b is not a file."

fn='-misc-dejavu sans mono-medium-r-*-*-*-140-*-*-m-*-*-*'
geom='957x1080-0+0'

set -A opts -- -buttons close:0 -default close -fn "$fn" -geometry "$geom"
xmessage "${opts[@]}" -file "$1"

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
