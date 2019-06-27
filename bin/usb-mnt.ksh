#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-10-09:tw/18.00.11z/24a1e93>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Mount any unmounted but attached USB devices.
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
while getopts ':h' Option; do
	case $Option in
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

: ${USER:?}
needs df awk egrep

doas true || doas true || doas true || die 'Could not ^Brootify^b.'

set -A fatopts -- -t msdos -s -o rw,noexec,nosuid,-g=$USER,-u=$USER
set -A ffsopts -- -t ffs -s -o rw,noexec,nodev,sync,softdep

function mnt-fs {
	dev=/dev/"$1"
	mntpnt=/vol/"$2"
	shift 2

	desparkle "$mntpnt";	mntpntD="$REPLY"
	desparkle "$dev";		devD="$REPLY"
	df -P | egrep -q "^$dev " && return 0
	[[ -d $mntpnt ]]|| doas mkdir "$mntpnt"
	(($?))&& {
		warn "Could not ^Tmkdir^t ^S$mntpntD^s."
		return 1
	  }
	notify fsck
	doas fsck -t $2 "$dev" || {
		warn "Could not ^Tfsck^t ^S$devD^s."
		return 1
	}
	notify mount "$@" "$dev" "$mntpnt"
	doas mount "$@" "$dev" "$mntpnt" || {
		warn "Could not ^Tmount^t ^S$devD^s."
		return 1
	  }
	notify "Mounted ^S$devD^s at ^S$mntpntD^s."
}

awkpgm="$(cat)" <<-\
	\==AWKPGM==
	/^label: /		{print substr($0,8)}
	/^  [abd-p]:/	{print $1,$4}
	==AWKPGM==

function mnt-drv {
	dev="$1"
	id="${2:-}"
	splitstr NL "$(doas disklabel "$dev" | awk "${awkpgm[@]}")" diskinfo
	label="${diskinfo[0]}"
	unset diskinfo[0]; set -A diskinfo -- "${diskinfo[@]}"
	label="${label%%+([[:space:]])}"
	((${#diskinfo[*]}==1))|| {
		warn 'Too many drives, bailing.'
		return 1
	  }

	part="${diskinfo%: *}"
	fstype="${diskinfo#*: }"

	case "$fstype" in
		MSDOS)	mnt-fs "$dev$part" "$label" "${fatopts[@]}";	;;
		4.2BSD)	mnt-fs "$dev$part" "$label" "${ffsopts[@]}";	;;
		*)		warn "Unknown type <^B$fstype^b>.";				;;
	esac
}

splitstr , "$(sysctl -n hw.disknames)" disknames
for d in "${disknames[@]}"; do
	[[ $d == sd0:* ]]&& continue
	desparkle "$d"
	notify "Trying to mount ^B$REPLY^b."
	mnt-drv "${d%%:*}" "${d#:}"
done

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
