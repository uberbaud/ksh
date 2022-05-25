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
	^F{4}Usage^f: ^T$PGM^t 
	         Watches several ^Ufiles^u and ^Tmakes^t things when one changes.
	         Defaults to watching ^O*^o^T.^t^O[^o^Tch^t^O]^o
	         If the changed file is a ^O*^o^T.h^t file, ^Tgrep^ts all ^O*^o^T.c^t files
	             for the included ^Bh^b file and makes the object for those.
	         If it's a ^O*^o^T.c^t file, makes only the object fot that one.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
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

needs fgrep h2 mkdep watch-file

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
