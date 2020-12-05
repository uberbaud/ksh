#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-11-22:tw/01.04.13z/9c71a1>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-d^t^] ^[^T-q^t^] ^Uwindowid^u
	         Flash the window with ^Uwindowid^u, switching desktops if necessary.
	         ^T-d^t  Do not switch desktops. Do nothing if a desktop switch would
	             be required.
	         ^T-q^t  Be ^Bquiet^b about switching desktops.
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
DOSWITCH=true
VERBOSE=true
while getopts ':dqh' Option; do
	case $Option in
		d)	DOSWITCH=false;											;;
		q)	VERBOSE=false;											;;
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
function warnOrDie { #{{{1
	case $warnOrDie in
		die)  die "$@" 'Use [1m-f22m to force an edit.';		;;
		warn) warn "$@";											;;
		*)    die '[1mProgrammer error[22m:' \
					'warnOrDie is [1m${warnOrDie}[22m.';		;;
	esac
} # }}}1
(($#))||	die 'Missing required argument ^Uwindowid^u.'
(($#>1))&&	die 'Too many arguments. Expected only one.'
[[ $1 == ?(0x)+([0-9]) ]]||
			die 'Parameter is not a ^Uwindowid^u.'

needs xdotool xwd convert display

set -A cvrtopts -- xwd:- \( -clone 0 -fill orange -colorize 100% \)
set -A cvrtopts -- "${cvrtopts[@]}" \( -clone 0 -colorspace Gray \)
set -A cvrtopts -- "${cvrtopts[@]}" -composite png:-
# wrap script guts in a function so edits to this script file don't 
# affect running instances of the script.
function main {
	c=$(xdotool get_desktop) || die "Could not get desktop."
	d=$(xdotool get_desktop_for_window $1) ||
		die "Could not get window's desktop."
	((c==d))|| {
		if $DOSWITCH; then
			xdotool set_desktop $d
		else
			$VERBOSE && warn 'Window is not on this desktop. Not switching.'
			return 0
		fi
	}

	xdotool windowraise $1 || die "Could not raise window."

	# make sure variables are not typeset weirdly
	unset WINDOW X Y WIDTH HEIGHT SCREEN
	eval "$(xdotool getwindowgeometry --shell $1)"
	(($1==WINDOW))||
		die 'Weird geometry results.' \
			"WINDOW $WINDOW, X $X, Y $Y, WIDTH $WIDTH, HEIGHT $HEIGHT"

	imgtitle="flash $1-$RANDOM"
	xwd -silent -id $1				|
		convert "${cvrtopts[@]}"	|
		display -title "$imgtitle" -geometry +$X+$Y - &

	imgpid=$!
	sleep 0.3

	imgwinid="$(xdotool search --name "$imgtitle")"
	xdotool windowraise $1;			sleep 0.2
	xdotool windowraise $imgwinid;	sleep 0.3
	xdotool windowraise $1;			sleep 0.2
	xdotool windowraise $imgwinid;	sleep 0.3
	kill $imgpid
} 2>/dev/null

main "$@"; exit

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
