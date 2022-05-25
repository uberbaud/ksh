#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2022-05-23,21.14.09z/2c44a1c>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^Usource files^u^]
	         Gets ^Utarget^: dependency^u information for ^Usource files^u and ^Tmake^ts
	             any targets when one of its watched dependencies changes.
	         Defaults to watching ^O*^o^T.^t^O[^o^Tch^t^O]^o
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
function get-dependencies { # {{{1
	local obj src deps d dlist
	h2 "updating dependency information"
	# `mkdep` calls $CC, so lets do it directly like it does, but without
	# creating a file.
	# Without -r, `read` concats lines ending with a backslash ('\').
	${CC:-clang} -M -w "$@" | while read obj src deps; do
		[[ $src == *.h ]]&& continue
		dlist=''
		for d in $src $deps; do
			[[ $d == /usr/* ]]|| dlist="$dlist $d"
		done
		[[ -n $dlist ]]&& print -r -- "${obj%:}$dlist"
	done >$TmpFile
} # }}}1
function prn-dependent-oes { # {{{1
	local ofile deps
	while IFS=' ' read -r ofile deps; do
		[[ " $deps " == *" ${1:?} "* ]]&&
			print -r -- "$ofile"
	done <$TmpFile
} # }}}1
function watch-file-w-h2 { # {{{1
	h2 "watching files $*" 1>&2
	watch-file -v "$@"
} # }}}1

needs h2 ${CC:-clang} watch-file

(($#))|| set -- *.[ch]
[[ $1 == \*.\[ch\] ]]&&
	die "Could not find files matching ^O*^o^T.^t^O[^o^Tch^t^O]^o."
HSP=' 	'

TmpFile=$(mktemp -t DEPENDS.XXXXXX) || die "Could not ^Tmktemp^t"
trap "rm $TmpFile" EXIT
h2 "Using $TmpFile"

get-dependencies "$@"

while f=$(watch-file-w-h2 "$@"); do
	print -r -- "$f changed"
	for o in $(prn-dependent-oes "$f"); do
		h2 "making $o"
		make "$o"
	done
done; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
