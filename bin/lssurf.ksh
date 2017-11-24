#!/bin/ksh
# @(#)[:JLIIde<tsIrrg)zO96>I: 2017-08-14 20:15:09 Z tw@csongor]
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

typeset hover=0 show=show-regular
# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t
	         List current location urls of all class=Surf windows.
	         ^T-l^t  Lists links under hover rather than location.
	         ^T-v^t  Show ^Bwinid^b and ^Bpid^b as well as the url.
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
while getopts ':lvh' Option; do
	case $Option in
		l)	hover=1;												;;
		v)	show=show-verbose;										;;
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

needs xdotool xprop

fmtVerbose='%-11s %-11s %s\n'
function show-regular-header { }
function show-regular { printf '%s\n' "$2"; }
function show-verbose-header { printf "$fmtVerbose" WINID PID URL; }
function show-verbose {
	printf "$fmtVerbose" $1 $(xprop -id $1 _NET_WM_PID|tr -cd [0-9]) $2;
}

set -A query -- '_SURF_URI' 'WM_NAME'
set -A xids -- $(xdotool search --class '^Surf$')

${show}-header
for id in "${xids[@]}"; do
	url="$(xprop -id $id ${query[hover]})"
	url="${url#*\"}"; url="${url%\"}" # remove quotes and everything outside
	((hover))&& url=${url#* | }
	if [[ $url == @(http|https|ftp):* ]]; then
		$show $id "$url"
	elif [[ $url == file:* ]]; then
		url="${url#file://}"
		[[ $url == $PWD/* ]]&& url="./${url#$PWD/}"
		[[ $url == $HOME/* ]]&& url="~/${url#$HOME/}"
		$show $id "$url"
	fi
done

# Copyright (C) 2010,2017 by Tom Davis <tom@greyshirt.net>.
