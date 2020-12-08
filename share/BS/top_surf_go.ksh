#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2019-07-24,04.14.19z/4e906ab>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

homepage="file://${XDG_DATA_HOME:?}/twSite/homepage.html"

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^Uurl^u]
	         Send the topmost surf to ^Uurl^u or homepage, if no ^Uurl^u given.
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

needs xprop

WID="$(xprop -root 32x ':$0' _NET_ACTIVE_WINDOW)"
WID="${WID##*:}"
xprop -id $WID -f _SURF_GO 8s -set _SURF_GO "${1:-$homepage}"

# Copyright (C) 2019 by Tom Davis <tom@greyshirt.net>.
