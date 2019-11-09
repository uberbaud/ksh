#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2019-11-08,00.17.58z/4dbb98e>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

Title='uberbaud-presentation' # <title>...</title> in html file
Display1='eDP-1'
initialURL="file://$XDG_DOCUMENTS_DIR/presentations/uberbaud-logo.html"

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
	^F{4}Usage^f: ^T$PGM^t ^[^T-x^t^|^T-l^t^] ^Upresentation^u
	         Initializes 2nd display, and starts the presentation and a terminal
	         on that display.
	           ^T-k^t  Kills the opened windows and turns off the display.
	           ^T-l^t  Enters loop.
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
while getopts ':klh' Option; do
	case $Option in
		k)	DO=off;												;;
		l)	DO=loop;											;;
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

PRESENTATION_FILE=
if [[ -n ${1:-} ]]; then
	if [[ -d $1 ]]; then
		PRESENTATION_FILE="$(readlink -fn "$1/present.html")"
	else
		PRESENTATION_FILE="$(readlink -fn "${1%.html}.html")"
	fi
	[[ -n $PRESENTATION_FILE ]]|| die "No such file ^B$1^b."
else
	PRESENTATION_FILE="$(readlink -fn present.html)"
fi
[[ -n "$PRESENTATION_FILE" ]]&& {
	[[ -a $PRESENTATION_FILE ]]|| die "^B$PRESENTATION_FILE^b does not exist."
	[[ -f $PRESENTATION_FILE ]]|| die "^B$PRESENTATION_FILE^b is not a file."
	[[ -s $PRESENTATION_FILE ]]|| die "^B$PRESENTATION_FILE^b is empty."
  }

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
	surfxid=$(xdotool search $* --name " $Title\$")
} #}}}1
function init_surf { #{{{1
	start surf "$initialURL"
	surf-xid --sync
	set_window_full_on_d2 $surfxid
	[[ -n $PRESENTATION_FILE ]]&&
		xprop -id $surfxid	\
			-f _SURF_GO 8s	\
			-set _SURF_GO "file://$PRESENTATION_FILE"
} #}}}1
function st-xid { #{{{1
	stxid=$(xdotool search $* --class '^presTerm$')
} #}}}1
function init_term { #{{{1
	st -c presTerm -f 'Liberation Mono:pixelsize=36:antialias=true' &
	st-xid --sync
	set_window_full_on_d2 $stxid
} #}}}1
function loop { #{{{1
	surf-xid
	st-xid
	warn '^Sloop^s is not implemented.'
} #}}}1
function on { #{{{1
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
} #}}}1

$DO; exit

# Copyright (C) 2019 by Tom Davis <tom@greyshirt.net>.
