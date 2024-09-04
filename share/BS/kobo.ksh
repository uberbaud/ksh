#!/bin/ksh
# <@(#)tag:tw.csongor.uberbaud.foo,2024-08-08,02.07.16z/44b0345>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

BOOKSHELF=${HOME:?}/docs/bookshelf/epub
dKOBO=/vol/kobo

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Add new bookshelf/epubs to kobo device.
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
function rewrite-trailing-bits-of-name { # {{{1
	local f in out
	in=${1:?}
	out=${2:-}
	set -- *$in
	[[ $1 == \*$in ]]&& return
	for f; do
		mv "$f" "${f%"$in"}$out"
	done
} # }}}1
function clean-local-names { #{{{1
	rewrite-trailing-bits-of-name .kepub.epub .epub
} # }}}1
function check-that-kobo-is-connected { # {{{1
	local usbdevname
	usbdevname=$( usbdevs | egrep -o '"Kobo |Composite Gadget' )
	case $usbdevname in
		Kobo*)	true;													;;
		Comp*)	die "^BKobo^b has not yet been recognized as a drive.";	;;
		*)		die "^BKobo^b is not attached to a USB port.";			;;
	esac
} # }}}1
function mount-kobo { # {{{1
	NOT-IMPLEMENTED -die
} # }}}1
function check-for-differing-versions { # {{{1
	NOT-IMPLEMENTED -die
} # }}}1
function copy-new-books-to-kobo { # {{{1
	NOT-IMPLEMENTED -die
} # }}}1
function copy-unmirrored-books-from-kobo { # {{{1
	NOT-IMPLEMENTED -die
} # }}}1
function unmount-kobo { # {{{1
	usb-umnt "$dKOBO"
} # }}}1
function main { # {{{1
	clean-local-names
	check-that-kobo-is-connected
	mount-kobo
	check-for-differing-versions
	copy-new-books-to-kobo
	copy-unmirrored-books-from-kobo
	unmount-kobo
} #}}}1

needs NOT-IMPLEMENTED
needs needs-path

needs-path -or-die "$BOOKSHELF"

main "$@"; exit

# Copyright (C) 2024 by Tom Davis <tom@greyshirt.net>.
