#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-08-14:tw/20.15.09z/2a9f555>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

fmtVerbose='%-11s %-11s %s\n'

show=show-regular
# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t
	         List current location urls of all class=Surf windows.
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
while getopts ':vh' Option; do
	case $Option in
		v)	show=show-verbose;										;;
		h)	usage;													;;
		\?)	die "Invalid option: [1m-$OPTARG[22m.";				;;
		\:)	die "Option [1m-$OPTARG[22m requires an argument.";	;;
		*)	bad_programmer "$Option";								;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
function show-regular-header { }
function show-regular { printf '%s\n' "$2"; }
function show-verbose-header { printf "$fmtVerbose" WINID PID URL; }
function show-verbose { # {{{1
	printf "$fmtVerbose" $1 $(xprop -id $1 _NET_WM_PID|tr -cd [0-9]) $2;
} # }}}1
function show-regular-nosurfs { }
function show-verbose-nosurfs { warn 'No Surfs found.'; }
function get-surf-uri { # {{{1
	local url
	url=$(xprop -notype -id ${1:?} -f _SURF_URI 8u ':  $0\n' _SURF_URI)
	url=${url#_SURF_URI:  }
	[[ $url == 'not found.' ]]&& return 1
	url=${url#\"}
	url=${url%\"}
	REPLY=$url
} # }}}1
function ls-every-surf { # {{{1
	(($#))|| { ${show}-nosurfs; return 0; }

	${show}-header
	for id; do
		get-surf-uri $id || continue
		url=$REPLY
		if [[ $url == file:* ]]; then
			url=${url#file://}
			[[ $url == $PWD/* ]]&& url="./${url#$PWD/}"
			[[ $url == $HOME/* ]]&& url="~/${url#$HOME/}"
			$show $id "$url"
		elif [[ $url == about:* ]]; then
			:
		else
			$show $id "$url"
		fi
	done
} # }}}1

needs xdotool xprop

ls-every-surf $(xdotool search --class '^Surf$'); exit

# Copyright (C) 2010,2017 by Tom Davis <tom@greyshirt.net>.
