#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2022-04-13,16.01.27z/4c3f9b8>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

SCANNER_DEVICE='Brother, DS-740D' # needs regex escapes if any
USB=
UGEN=

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         set things up for scanner ($SCANNER_DEVICE)
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
AWKPGM=$(</dev/stdin) <<-\
	\===AWK===
	/^Controller/		{controller=$2}
	match($0,DEV)		{found=1}
	found && /driver:/	{print controller,$2;exit}
	===AWK===
function get-drivers { # {{{1
	local scanner
	scanner=${1:?Missing Scanner ID}
	set -- $(usbdevs -v | awk -v DEV="$scanner" "$AWKPGM")
	(($#))|| die "Did not find connection for ^B$scanner^b."
	USB=${1%:}
	UGEN=/dev/$2
} # }}}1
# wrap script guts in a function so edits to this script file don't 
# affect running instances of the script.
function main {
	get-drivers "$SCANNER_DEVICE"
	as-root chown "$(id -un)" $USB $UGEN.*
}

main "$@"; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
