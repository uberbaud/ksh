#!/bin/ksh
# <@(#)tag:tw.lukas.uberbaud.foo,2026-01-25,17.54.13z/3257263>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: "${FPATH:?Run from within KSH}"

fDEP=.depend
fSRC=
fOUT=
# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm" PGM
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-n^t^|^T-d^t ^UdepFile^u^] ^[^T-w^t ^Uwatchlist^u^] ^T-s^t ^Usource^u ^[^UdepObjs^u ^S…^s^]
	         Create a ^Tbuild-and-run^t watch list using the output of ^Tmkdep^t
	         and the ^UdepObjs^u given on the command line.
	           ^T-d^t ^UdepFile^u    Dependency file for ^Tmake^t, defaults to ^T.depend^t.
	           ^T-n^t            Do ^BNOT^b write a dependency file.
	           ^T-s^t ^Usource^u     The ^BC^b file to process.
	           ^T-w^t ^Uwatchlist^u  The output file.
	         ^GNote: Does not run^g ^Tmkdep^t^G.^g
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
verbose=false
wantdep=true
while getopts ':dn:s:w:h' Option; do
	case $Option in
		d)	fDEP=$OPTARG;													;;
		n)	wantdep=false;													;;
		s)	fSRC=$OPTARG;													;;
		w)	fOUT=$OPTARG;													;;
		h)	usage;															;;
		\?)	die USAGE "Invalid option: ^B-$OPTARG^b.";						;;
		:)	die USAGE "Option ^B-$OPTARG^b requires an argument.";			;;
		*)	bad-programmer "No getopts action defined for ^T-$Option^t.";	;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
function main { # {{{1
	local o obj d deps
	exec 3>$fOUT
	$wantdep && exec 4>$fDEP
	# get the .o target to match against
	fOBJ=${fSRC##*/}; fOBJ=${fOBJ%.c}.o
	$CC ${CFLAGS:-} -MM -w $fSRC | while IFS=":$IFS" read obj deps; do
		$wantdep && print -ru4 -- "$obj: $deps"
		[[ $obj == $fOBJ ]]&& for d in $deps; do
			print -ru3 -- "$d"
		done
	done
	# print the other object files
	for o { print -ru3 -- "$d"; }
	exec 3>&-
	$wantdep && exec 4>&-
} #}}}1

needs needs-file ${CC:=cc}

[[ -n $fSRC ]]|| die "Missing required ^T-t^t parameter."

[[ -n $fOUT ]]|| fOUT=${fSRC%.c}.wlst
touch "$fOUT" || die "Could not access ^B$fOUT^b."


main "$@"; exit
# Copyright (C) 2026 by Tom Davis <tom@greyshirt.net>.
