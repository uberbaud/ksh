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
function CleanUp { # {{{1
	builtin cd "${1:?}" || return
	pwd
	clearout
} # }}}1
function get-dependencies { # {{{1
	local f D o
	D=$TmpPath/DEPENDS
	for f; do
		[[ $f == *[$HSP]* ]]&& die "Filename contains spaces:" "^U$f^u."
		[[ -a $f ]]|| die "^U$f^u does not exist."
		[[ -f $f ]]|| die "^U$f^u is not a file."
		[[ $f == *.c ]]|| continue
		o=$TmpPath/${f%.[ch]}.o
		mkdep -f $D $f
		tr ' ' '\n' <$D |
			sed -E -e '1,2d' -e '/\\/d' -e '/^$/d' -e '/\/usr\//d' >$o
	done
	rm $D
} # }}}1
function prn-dependent-oes { # {{{1
	fgrep -l "$1" $TmpPath/* |
		while IFS= read l; do
			print -- "${l#"$TmpPath"/}"
		done
} # }}}1

needs fgrep h2 mkdep watch-file

(($#))|| set -- *.[ch]
[[ $1 == \*.\[ch\] ]]&&
	die "Could not find files matching ^O*^o^T.^t^O[^o^Tch^t^O]^o."
HSP=' 	'

TmpPath=$(mktemp -d) || die "Could not ^Tmktemp^t."
trap "CleanUp ${TmpPath}" EXIT

get-dependencies "$@"

while f=$(watch-file -v "$@"); do
	h2 "$f changed"
	for o in ${f%.[ch]}.o $(prn-dependent-oes "$f"); do
		h2 "making $o"
		make "$o"
	done
done; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
