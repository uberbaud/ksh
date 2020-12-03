#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2020-09-14,13.17.17z/31deee3>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# `sndioctl` expects a level in the range of 0 to 1 inclusive, however
# internally it seems (based on previous documentation) that it is using
# integer values in the range of 0-127.
# HOWEVER, my sound decoders seem to have steps every 4 of those values,
# or an integer range of 0-31, so that's what we're using
# AND $(dc -e '5k 4 128/p') -> .03125
vstep='0.03125'

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^Uvolume^u^|^T+^t^|^T-^t^|^T-m^t^|^Tmute^t^|^T-t^t^|^Ttoggle-mute^t^]
	         Change the volume. ^Uvolume^u can be as a percent, or a
	         float between 0 and 1, or a ^T+^t or ^T-^t to increase or decrease.
	           ^T-m^t^|^Tmute^t^*         mute on
	           ^T-t^t^|^Ttoggle-mute^t^*  toggle mute
	               ^*^/ everything after the initial ^Tm^t or ^Tt^t is ignored

	         If no argument is given, ^T$PGM^t prints the current volume.

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
while getopts ':mh' Option; do
	case $Option in
		m)	set mute;											;;
		t)	set toggle-mute;									;;
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
function mute { # {{{1
	sndioctl -q output.mute=1
} # }}}
function toggle-mute { # {{{1
	sndioctl -q output.mute=$((!$(sndioctl -n output.mute)))
} # }}}
function set-volume		{ # {{{1
	sndioctl output.level${1:+=$1} |
		tee $XDG_CONFIG_HOME/etc/sndioctl.rc
} # }}}1
function set-as-percent	{ set-volume $(dc -e "3k ${1%\%} 100/p");	}
function adjust-volume { # {{{1
	local op=$1
	set -- $(sndioctl -n output.level output.mute)
	(($2))&& { # don't adjust if we're muted, just unmute
		sndioctl -q output.mute=0
		return
	  }
	set-volume $(dc -e "5k $1 $vstep $op p")
} # }}}1
function bad-volume-fmt { # {{{1
	desparkle "$1"
	die 'Bad volume format'										\
		"Found: ^B$REPLY^b"										\
		'Expected ^Iunit range^i: ^T0.000^t−^T1.000^t, or'	\
		'         ^Ipercentage^i: ^T0^t−^T100^t, or'			\
		'         ^Iadjustment^i: ^T+^t or ^T-^t'
} # }}}1


# wrap script guts in a function so edits to this script file don't 
# affect running instances of the script.
function main {
	case "${1:-}" in
		0.+([0-9])?(%))				set-volume		$1;		;;
		1?(.*(0)))					set-volume		1;		;;
		?([0-9])[0-9]?(.*([0-9])))	set-as-percent	$1;		;;
		100?(.*(0))?(%))			set-volume		1;		;;
		+|-)						adjust-volume	$1;		;;
		'')							set-volume		'';		;;
		m*)							mute;					;;
		t*)							toggle-mute;			;;
		*)							bad-volume-fmt	$1;		;;
	esac
}

main "$@"; exit


# Copyright (C) 2020 by Tom Davis <tom@greyshirt.net>.