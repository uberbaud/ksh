#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2021-11-03,16.23.56z/22e02e2>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

warnOrDie=die
new-array xwd_opts

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t  ^[^Uxwd options^u^] ^[^T--^t ^Uconvert options^u^] ^Uoutput file^u
	         Use ^Txwd^t and ^IImageMagick^i's ^Tconvert^t to capture an X11 window
	         to an image file.
	           ^T-f^t       Force overwrite of existing ^Uoutput file^u.
	         ^Txwd^t options:
	           ^T-d^t ^Udpy^u   Use display ^[^Uhost^u^T:^t^]^Udpy^u.
	           ^T-i^t ^Uid^u    Capture window with resource id ^Uid^u.
	           ^T-n^t ^Uname^u  Capture window with ^BWM_NAME^b ^Uname^u.
	           ^T-r^t       Capture root window.
	           ^T-s^t       Capture sub-windows too (eg: menus).
	           ^T-b^t       Exclude window borders.
	           ^T-q^t       Quiet. Don't ring any bells.
	         ^Tconvert^t options:
	           Convert options are exactly as given in ^Bconvert(1)^b and MUST
	           be preceeded by ^T--^t to separate them from the ^Txwd^t options.

	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
w=false
function too-many-selections { # {{{2
	die "^T-i^t, ^T-n^t, and ^T-r^t are mutually exclusive."
} # }}}2
while getopts ':fhdi:n:rbqs' Option; do
	case $Option in
		# our very own option
		f)	warnOrDie=warn;													;;
		h)	usage;															;;
		# xwd options
		# display
		d)	+xwd_opts -display "$OPTARG";									;;
		# capture which window
		i)	$w && too-many-selections; +xwd_opts -id "$OPTARG"; w=true;		;;
		n)	$w && too-many-selections; +xwd_opts -name "$OPTARG"; w=true;	;;
		r)	$w && too-many-selections; +xwd_opts -root; w=true;				;;
		# other options
		b)	+xwd_opts -nobdrs;												;;
		q)	+xwd_opts -silent;												;;
		s)	+xwd_opts -screen;												;;
		# ERRORS
		\?)	die "Invalid option: ^B-$OPTARG^b.";							;;
		\:)	die "Option ^B-$OPTARG^b requires an argument.";				;;
		*)	bad-programmer "No getopts action defined for ^T-$Option^t."	;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1

(($#))|| die "Missing required argument ^Uoutput file^u."

needs xwd convert

eval ofile=\$$#		# output file is the LAST parameter
ofile=${ofile#*:}	# convert allows an image format to be prepended with
					#   a colon separating the format from the file
					#   name.
[[ -f $ofile ]]&& warnOrDie "^B$ofile^b exists."

xwd ${xwd_opts[*]:+"${xwd_opts[@]}"} | convert xwd:- "$@"

# Copyright (C) 2021 by Tom Davis <tom@greyshirt.net>.
