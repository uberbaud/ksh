#!/bin/ksh
# <@(#)tag:tw.lukas.uberbaud.foo,2026-01-25,17.54.13z/3257263>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm" PGM
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Create a ^Tfuddle^t watch list.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
verbose=false
while getopts ':hv' Option; do
	case $Option in
		v)	verbose=true;													;;
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
	$verbose && {
		local dOUT
		desparkle "$fOUT" dOUT
		notify "fOUT ^= ^B$dOUT^b"
	  }
	mkdep -f "$fOUT" $CFLAGS -MM "$TARGET"
	set -- $(<$fOUT) "$@"
	for o; do
		[[ $o == '\' ]]&& continue
		[[ ${o%:} == $BASE.o ]]&& continue
		print -r -- "${o%:}"
	done | sort | uniq >$fOUT
} #}}}1

needs needs-file mkdep

(($#))|| die "Missing required parameter ^Utarget^u."
TARGET=$1;	shift
needs-file -or-die "$TARGET"

[[ $TARGET == *.c ]]|| die "Expected target to be ^BC^b ^Isource code^i file."

OUT=$(realpath "$TARGET")
BASE=${OUT##*/}; BASE=${BASE%.c}
pOUT=${OUT%/*}
OUT=${OUT#$pOUT}; OUT=${OUT#/}
fOUT=${OUT%.c}.wlst
if [[ -d $pOUT/watch ]]; then
	fOUT=$pOUT/watch/$fOUT
else
	fOUT=$pOUT/$fOUT
fi

main "$@"; exit

# Copyright (C) 2026 by Tom Davis <tom@greyshirt.net>.
