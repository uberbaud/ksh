#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2022-07-20,00.29.42z/a78609>
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
	         Process config.h to get dwm key to function mapping.
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
	BEGIN { p=1; M="undefined" }
	/^#[[:space:]]*define[[:space:]]+MODKEY/ { M=$NF; }
	/^static Key keys\[\] = {/ { p=0; FS=",[[:space:]]*" }
	p { next }
	/};/ { exit }
	/^[[:space:]]*{/ {
			sub(/^[[:space:]]*{[[:space:]]*/,"");
			sub(/[[:space:]]*}[[:space:]]*,[!,]*$/,"");
			gsub(/MODKEY/,M,$1);
			gsub(/Mask/,"",$1);
			gsub(/\|/,"+",$1);

			gsub(/XK_/,"",$2);

			sub(/^{[[:space:]]*/,"",$4);
			sub(/[[:space:]]*}[[:space:]]*$/,"",$4);
			sub(/\.(ui|i|f|v)[[:space:]]*=[[:space:]]*/,"",$4);
			if ($4 ~ /&layouts\[/) {
					sub(/^&layouts\[Layout/,"",$4);
					sub(/\]/,"",$4);
				}
			k=$1"+"$2
			if ($4=="0")	printf("  %-20s %s\n",k,$3);
			else 			printf("  %-20s %s %s\n",k,$3,$4);
		}

	===AWK===

# wrap script guts in a function so edits to this script file don't 
# affect running instances of the script.
function main {
	awk "$AWKPGM" $CFG
}

CFG=$(realpath -q ~/src/tw-needs/dwm/config.h)
needs-file -or-die "$CFG"
main "$@"; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
