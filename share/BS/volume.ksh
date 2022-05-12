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
sndiorc=${XDG_CONFIG_HOME}/etc/sndioctl.rc

# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^Uvolume^u^|^T+^t^|^T-^t^|^T-m^t^|^Tmute^t^|^T-t^t^|^Ttoggle-mute^t^]
	         Change the volume. ^Uvolume^u can be as a percent, or a
	         float between 0 and 1, or a ^T+^t or ^T-^t to increase or decrease.
	           ^T-l^t               Use ^Blocal device^b regardless of ^VAUDIODEVICE^v, etc.
	           ^T-m^t^|^Tmute^t^*         mute on
	           ^T-t^t^|^Ttoggle-mute^t^*  toggle mute
	               ^*^/ everything after the initial ^Tm^t or ^Tt^t is ignored
	           ^T-r^t^|^Treload^t^*       reload ^Bsndiod^b

	         If no argument is given, ^T$PGM^t prints the current volume.

	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
USE_LOCAL_DEVICE=false
function bad_programmer {	# {{{2
	die 'Programmer error:'	\
		"  No getopts action defined for [1m-$1[22m."
  };	# }}}2
while getopts ':lmrth' Option; do
	case $Option in
		l)	USE_LOCAL_DEVICE=true;								;;
		m)	set mute;											;;
		t)	set toggle-mute;									;;
		r)	set reload;											;;
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
	set -- $(sndioctl -n output.mute)
	(($1))&& { # don't adjust if we're muted, just unmute
		sndioctl -q output.mute=0
		return
	  }
	set-volume $op$vstep
} # }}}1
function bad-volume-fmt { # {{{1
	desparkle "$1"
	die 'Bad volume format'										\
		"Found: ^B$REPLY^b"										\
		'Expected ^Iunit range^i: ^T0.000^t−^T1.000^t, or'	\
		'         ^Ipercentage^i: ^T0^t−^T100^t, or'			\
		'         ^Iadjustment^i: ^T+^t or ^T-^t'
} # }}}1
function reset-volume { #{{{1
	local volnow volset
	volnow=$(sndioctl output.level)
	[[ -s $sndiorc ]]||
		return # we don't have a saved volume for this device

	volset=$(<$sndiorc)
	[[ $volnow == $volset ]]|| {
		notify "Resetting volume to ^B$volset^b ^G(from ^B$volnow^b)^g."
		sndioctl -q $volset
	  }
} #}}}1
function reload	 { #{{{1
	doas rcctl reload sndiod
	reset-volume
} #}}}1
function main { # {{{1
	notify "Using ^B${AUDIODEVICE:-"^G^Idefault local sndio device^i^g"}^b"
	reset-volume

	case "${1:-}" in
		0.+([0-9])?(%))				set-volume		$1;		;;
		1?(.*(0)))					set-volume		1;		;;
		?([0-9])[0-9]?(.*([0-9])))	set-as-percent	$1;		;;
		100?(.*(0))?(%))			set-volume		1;		;;
		+|-)						adjust-volume	$1;		;;
		'')							set-volume		'';		;;
		m*)							mute;					;;
		r*)							reload;					;;
		t*)							toggle-mute;			;;
		*)							bad-volume-fmt	$1;		;;
	esac

	sndioctl output.level >$sndiorc
} # }}}1

needs needs-file

if $USE_LOCAL_DEVICE; then
	unset AUDIODEVICE
else
	needs amuse:env
	amuse:env
	fAudDev=${AMUSE_RUN_DIR:?}/audiodevice
	[[ -z ${AUDIODEVICE:-} && -s $fAudDev ]]&&
		export AUDIODEVICE=$(<$fAudDev)
fi

# give each snd@machine/device its own rc file
[[ ${AUDIODEVICE:-} == *@* ]]&& {
	h=${AUDIODEVICE#*@}
	d=${AUDIODEVICE#*/}
	h=${h%/*}
	[[ -n $h ]]&&
		sndiorc=${sndiorc%.rc}.$h.$d.rc
  }


[[ -a $sndiorc ]]|| : >$sndiorc
needs-file -or-die "$sndiorc"
[[ -w $sndiorc ]]|| chmod u+w $sndiorc
main "$@"; exit

# Copyright (C) 2020 by Tom Davis <tom@greyshirt.net>.
