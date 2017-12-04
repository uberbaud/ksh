#!/bin/ksh
# @(#)[:a#ZEfmi9se5w~YmSF?Ad: 2017-08-08 00:54:34 Z tw@csongor]
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t
	         save a mail part to disk and try to open it.
	       ^T${PGM} -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
function bad_programmer {	# {{{2
	die 'Programmer error:'	\
		"  No getopts action defined for [1m-$1[22m."
  };	# }}}2
forceHTML=false
while getopts ':hH' Option; do
	case $Option in
		H)	forceHTML=true;											;;
		h)	usage;													;;
		\?)	die "Invalid option: [1m-$OPTARG[22m.";				;;
		\:)	die "Option [1m-$OPTARG[22m requires an argument.";	;;
		*)	bad_programmer "$Option";								;;
	esac
done
# remove already processed arguments
shift $(($OPTIND - 1))
# ready to process non '-' prefixed arguments
# /options }}}1

work=${XDG_CACHE_HOME:?}/mail

[[ -d $work ]]|| mkdir -p "$work" || die "Could not create ^S$work^s."
cd "$work" || die "Could not ^Tcd^t to ^S$work^s."
printf 'In \e[35m$XDG_CACHE_HOME/mail\e[39m\n'

new-array parts

touch mark-$$
mhstore "$@"
for f in *; do
	[[ $f -nt mark-$$ ]]&& continue # skip old files
	if [[ $f == *.txt && "$( file -bi "$f" )" == text/html ]]; then
		H="${f%.*}.html"
		mv "$f" "$H" && f="$H"
	elif [[ $f == *.html ]]; then
		:
	elif $forceHTML; then
		H="${f%.*}.html"
		mv "$f" "$H" && f="$H"
	fi
	+parts "$f"
done
rm mark-$$

open "${parts[@]}"

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
