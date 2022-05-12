#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2022-04-20,04.14.45z/1526c88>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

PAGESIZE=letter
DENSITY=72
# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-f^t^] ^Uimage files …^u ^Ucombined pdf^u
	         Join a number of image files and PDFs into a single PDF,
	         one image file per page.
	         ^T-p^t ^Upage size^u  ^Uletter^u, ^Ua4^u, etc
	         ^T-f^t  Force overwrite of output ^Ucombined pdf^u file.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
warnOrDie=die
FORCE_MSG='Use ^T-f^t to force overwrite.'
while getopts ':fh' Option; do
	case $Option in
		f)	warnOrDie=warn;													;;
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
	local image pdf i pages options
	options="-units pixelsperinch -density $DENSITY -page $PAGESIZE"
	i=0
	for image; do
		pdf=${image%.*}.pdf
		[[ $image != $pdf ]]&&
			convert "$image" $options "$pdf"
		pages[i++]=$pdf
	done
	pdfunite "${pages[@]}" "$COMBINED_PDF"
} # }}}1

needs convert

(($#>1))|| die "Missing required parameters ^Upages …^u and ^Ucombined^u."

# verify input files
unset INFILES
i=0
while (($#>1)); do
	needs-file -or-warn "$1" || continue
	INFILES[i++]=$1
	shift
done

# verify output file
[[ $1 == *.pdf ]]|| die "^B$1^b must be *.pdf"
[[ -a $1 ]]&& {
	[[ -f $1 ]]|| die "^B$1^b exists and is not a file."
	warnOrDie "^B$1^b already exists."
}
COMBINED_PDF=$1

main "${INFILES[@]}"; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
