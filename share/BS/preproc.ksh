#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2022-06-26,00.05.45z/33fb84e>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

XXDIFF=/usr/local/bin/xxdiff
# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^UC Source Code^u
	         Runs ^UC Source Code^u through the preprocessor and if ^Sstdout^s
	           is a terminal, ^Tdiff^ts the original and expanded versions, or
	           if ^Sstderr^s has been redirected, spews the expanded version.
	         Uses ^O\${^o^VDIFF^v^O:-^o^T$XXDIFF^t^O}^o.
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
	local f
	[[ -n "${1:-}" ]]||
		bad-programmer "$0: Missing parameter 1: ^Utemp dir^u."
	for f in preproc.i clean.c; do
		[[ -f $1/$f ]]&& rm -f $1/$f
	done
	rmdir "$1"
} # }}}1
function workit { # {{{1
	local fPreProc=$1 mark=$2 fSrc=$3
	print -r -- "// preprocessed $fSrc"
	sed -E -e "1,${mark}d" -e '/^[[:space:]]*#/d' <$fPreProc
} # }}}1

needs awk cc needs-file sed

(($#))||	die 'Missing required parameter ^TC Source Code^t'
typeset -i10 i=0
set -A cflags --
while (($#>1)) { cflags[i++]=$1; shift; }

if [[ $1 == *.c ]]; then
	target=${1%.c}.i
	src=$1
elif [[ $1 == *.i ]]; then
	target=$1
	src=${1%.i}.c
else
	target=$1.i
	src=$1.c
fi
needs-file -or-die "$src"
src=$(realpath "$src") || die "Weirdly, ^Trealpath^t can't do ^B$src^b."

awkpgm=$(</dev/stdin) <<-\
	\===AWK===
	BEGIN {x=0}
	/^# [0-9]+ "/ { if ($2 == src) x=FNR }
	END {print x}
	===AWK===

pTmp=$(mktemp -d) || die 'Could not ^Tmktemp^t.'
[[ -t 1 ]]&& print -r -- "// mktemp -> $pTmp"
trap "CleanUp '$pTmp'" EXIT
iTmp=$pTmp/preproc.i

fuddle ${cflags:+"${cflags[@]}"} "$target" >$iTmp
delTo=$(awk -v src="$src" -F'"' "$awkpgm" <$iTmp)
((delTo))|| die "Could not find file start marker."

cTmp=$pTmp/clean.c
workit "$iTmp" "$delTo" "$src" | cat -s >$cTmp
#nvim -Rd "$src" "$cTmp"
if [[ -t 1 ]]; then
	D=${DIFF:-${XXDIFF:?BAD PROGRAMMER, XXDIFF is not set}}
	needs "$D"
	if (ldd $(which $D) | sed 1d | egrep -q X11R6) >/dev/null 2>&1; then
		($D "$src" "$cTmp"; CleanUp "$pTmp") >/dev/null 2>&1 &
		trap - EXIT
		notify "^B${D##*/}^b started"
	else
		$D "$src" "$cTmp"
	fi
else
	print -r -- "$(<$cTmp)"
fi; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
