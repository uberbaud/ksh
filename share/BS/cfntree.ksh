#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2021-02-04,21.19.26z/42bccc>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

SkipDiagram=true
OutFile=cfntree.out
# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-d^t^] ^[^Ubase dir^u^|^Ufiles ...^u^]
	         cscope + tceetree '^[+ graphviz^]
	           ^T-d^t  display results
	         output saved to ^B$OutFile^b
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
while getopts ':dh' Option; do
	case $Option in
		d)	SkipDiagram=false;									;;
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
function warnOrDie { #{{{1
	case $warnOrDie in
		die)  die "$@" 'Use [1m-f22m to force an edit.';		;;
		warn) warn "$@";											;;
		*)    die '[1mProgrammer error[22m:' \
					'warnOrDie is [1m${warnOrDie}[22m.';		;;
	esac
} # }}}1
function hCleanup { # {{{1
	rm -rf "$TEMP_PATH"
} # }}}1

needs cscope tceetree dot

(($#))|| set -- .
SRC_PATH=$(readlink -fn "$1")
TEMP_PATH=$(mktemp -d)
trap hCleanup EXIT

filelist=$TEMP_PATH/src-files
cscope_out=$TEMP_PATH/cscope.out
dotfile=$TEMP_PATH/cfuncs.dot

if [[ -d $SRC_PATH ]]; then
	find "$SRC_PATH" -name '*.c'
else
	for f; do
		[[ -f $f ]]|| { warn "^B$f^b is not a file."; continue; }
		print -r -- "$f"
	done
fi | sed -E -e '/[[:space:]["\\]/{s/["\\]/\\&/g;s/.*/"&"/;}' >$filelist

# wrap script guts in a function so edits to this script file don't 
# affect running instances of the script.
function main {
	cscope -b -c -R -i"$filelist" -f"$cscope_out"
	tceetree -x LIBRARY -o "$OutFile" -i "$cscope_out"
	$SkipDiagram && dot -Tdot "$OutFile" |display
}

main "$@"; exit

# Copyright (C) 2021 by Tom Davis <tom@greyshirt.net>.
