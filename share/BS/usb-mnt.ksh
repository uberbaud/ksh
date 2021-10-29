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
function mnt-fs { # {{{1
	local dev mntpnt mntpntD devD
	dev=/dev/"$1"
	mntpnt="$2"
	shift 2

	desparkle "$mntpnt";	mntpntD="$REPLY"
	desparkle "$dev";		devD="$REPLY"
	df -P | egrep -q "^$dev " && return 0 # already mounted
	needs-path -or-warn "$mntpnt" || return
	
	$WANT_FSCK && {
		notify fsck
		as-root fsck -t $2 "$dev" || {
			warn "Could not ^Tfsck^t ^S$devD^s."
			return 1
		  }
	  }
	notify "mount $* $dev $mntpnt"
	as-root mount "$@" "$dev" "$mntpnt" || {
		warn "Could not ^Tmount^t ^S$devD^s."
		return 1
	  }
	notify "Mounted ^S$devD^s at ^S$mntpntD^s."
} # }}}1
function mount-fs-ondev-at { # {{{1
	local fstype devpart mntpnt
	fstype="$1"
	devpart="$2"
	mntpnt="$3"

	case "$fstype" in
		MSDOS)		mnt-fs "$devpart" "$mntpnt" $fatopts;		;;
		4.2BSD)		mnt-fs "$devpart" "$mntpnt" $ffsopts;		;;
		ISO9660)	WANT_FSCK=false
					mnt-fs "$devpart" "$mntpnt" $cdopts
					;;
		*)		warn "Unknown type <^B$fstype^b>.";				;;
	esac
} # }}}1
# mnt-drv and resources {{{1
awkpgm="$(</dev/stdin)" <<-\
	\==AWKPGM==
	function printname() {
		if (label)		print label;
		else if (disk)	print disk;
		else			print "unknown"
	}
	/^disk: /		{disk=substr($0,7)}
	/^label: /		{label=substr($0,8)}
	/^$/			{printname()}
	/^  [abd-p]:/	{print $1,$4}
	==AWKPGM==


function mnt-drv {
	local dev diskinfo fstype id label namefile newlabel part
	dev="$1"
	id="${2:-}"
	splitstr NL "$(as-root disklabel "$dev" | awk "${awkpgm[@]}")" diskinfo
	label="${diskinfo[0]}"
	unset diskinfo[0]; set -A diskinfo -- "${diskinfo[@]}"
	label="${label%%+([[:space:]])}"
	((${#diskinfo[*]}==1))|| {
		warn 'Too many drives, bailing.'
		return 1
	  }

	part="${diskinfo%: *}"
	fstype="${diskinfo#*: }"
	WANT_FSCK=true
	mount-fs-ondev-at "$fstype" "$dev$part" /vol/"$label"

	# rename mount point IF there's a non-empty devname.txt file
	namefile=/vol/"$label"/devname.txt
	[[ -f $namefile ]]&& {
		newlabel=$(<$namefile)
		[[ -n $newlabel && $newlabel != $label ]]&& {
			as-root umount /vol/"$label"
			rmdir /vol/"$label"
			WANT_FSCK=false
			mount-fs-ondev-at "$fstype" "$dev$part" /vol/"$newlabel"
		  }
	  }

} # }}}1

: ${USER:?}
needs df awk egrep as-root needs-path

ffsopts='-t ffs -s -o rw,noexec,nodev,sync,softdep'
fatopts="-t msdos -s -o rw,noexec,nosuid,-g=$USER,-u=$USER"
cdopts="-t cd9660 -s -o rw,noexec,nosuid,-g"

function as-root { "$@"; }
function main {
	splitstr , "$(sysctl -n hw.disknames)" disknames
	for d in "${disknames[@]}"; do
		[[ $d == sd0:* ]]&& continue
		desparkle "$d"
		notify "Trying to mount ^B$REPLY^b."
		mnt-drv "${d%%:*}" "${d#:}"
	done
}

main "$@"; exit

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
