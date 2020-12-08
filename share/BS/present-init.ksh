#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2019-11-08,00.17.58z/4dbb98e>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

: ${XDG_DOCUMENTS_DIR:?}
initialURL="file://$XDG_DOCUMENTS_DIR/presentations/uberbaud-logo.html"
Title='uberbaud-presentation' # <title>...</title> in html file
Display1='eDP-1'

PGMBIN="$(readlink -fn "$0")"
PGMDIR="${PGMBIN%/*}"
desparkle "$PGMDIR"
dPGMDIR="$REPLY"

DO=on

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-k^t^]
	         Initializes 2nd display, and starts the presentation and a terminal
	         on that display.
	           ^T-k^t  Kills the opened windows and turns off the display.
	           ^Upresentation^u  opens the file or ^S^Upresentation^u/present.html^s.
	             If no ^Upresentation^u is given, attempts to open ^S./present.html^s.
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
while getopts ':kh' Option; do
	case $Option in
		k)	DO=off;												;;
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

(($#))&& die 'Unexpected parameters.'

function init_2nd_display { #{{{1
	local geom
	set -- $(xrandr|egrep -v "^$Display1 "|awk '/ connected /')
	[[ -n ${1:-} ]]||
		die 'No ^Bconnected^b second display found.'

	Display2="$1"
	xrandr --output "$Display2" --auto --right-of "$Display1"
	set -- $(xrandr|awk "/^$Display2 /")
	shift # we already have Display2 and we want to shift later
	[[ $2 == 'primary' ]]&& {
		warn "Unexpectedly, ^S$Display2^s is set as ^Bprimary^b."
		shift
	  }
	[[ $1 == 'connected' ]]||
		die 'Unexpected, ^S$Display2^s is no longer connected.'
	geom=$2
	d2Width=${geom%x*}
	geom=${geom#*x}
	d2Height=${geom%%+*}
	geom=${geom#*+}
	d2X=${geom%+*}
	d2Y=${geom#*+}
	[[ $d2Y == 0 ]]||
		warn "Unexpectedly, ^S$Display2^s has a ^By-offset^b of ^B$d2Y^b."
	DESKTOP=$(xdotool get_desktop)
} #}}}1
function set_window_full_on_d2 { #{{{1
	xdotool windowsize $1 $d2Width $d2Height
	xdotool windowmove $1 $d2X $d2Y
	xdotool set_desktop_for_window $1 -1 # sticky / every window
} #}}}1
function surf-xid { #{{{1
	surfxid=${SURF_XID:-"$(xdotool search $* --name " $Title\$")"}
} #}}}1
function init_surf { #{{{1
	start surf "$initialURL"
	surf-xid --sync
	set_window_full_on_d2 $surfxid
} #}}}1
function st-xid { #{{{1
	stxid=${ST_XID:-"$(xdotool search $* --class '^presTerm$')"}
} #}}}1
function init_term { #{{{1
	st -c presTerm -f 'Liberation Mono:pixelsize=36:antialias=true' &
	st-xid --sync
	set_window_full_on_d2 $stxid
} #}}}1
function on { #{{{1
# close any open windows with --name " uberbaud-present$"
	init_2nd_display
	init_surf
	init_term
	loop
} #}}}1
function off { #{{{1
	surf-xid
	st-xid
	xdotool windowclose $stxid
	xdotool windowclose $surfxid
	set -- $(xrandr|egrep -v "^$Display1 "|awk '/ connected / {print $1}')
	for D { xrandr --output $D --off; }
	surfxid=
} #}}}1

function put-cmds { #{{{1
	print -r -- "SURF_XID=${surfxid:-}"
	print -r -- "ST_XID=${stxid:-}"
	print -r -- "export SURF_XID ST_XID"
} #}}}1

$DO; put-cmds; exit

# Copyright (C) 2019 by Tom Davis <tom@greyshirt.net>.
