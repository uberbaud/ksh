#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-10-09:tw/18.00.11z/24a1e93>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-n^t^]
	         Mount any unmounted but attached USB devices.
	           ^T-n^t  Don't do otherwise automatic ^Bfsck^b.
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
WANT_FSCK=true
while getopts ':nh' Option; do
	case $Option in
		n)	WANT_FSCK=false;										;;
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
function mnt-fs { # {{{1
	local dev mntpnt mntpntD devD
	dev=/dev/"$1"
	mntpnt=$2
	shift 2

	desparkle "$mntpnt";	mntpntD=$REPLY
	desparkle "$dev";		devD=$REPLY
	df -P | egrep -q "^$dev " && return 0 # already mounted
	needs-path -create -or-warn "$mntpnt" || return
	
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
	fstype=$1
	devpart=$2
	mntpnt=$3


	case "$fstype" in
		MSDOS)		mnt-fs "$devpart" "$mntpnt" $fatopts;		;;
		4.2BSD)		mnt-fs "$devpart" "$mntpnt" $ffsopts;		;;
		NTFS)		WANT_FSCK=false
					mnt-fs "$devpart" "$mntpnt" $ntfsopts;		;;
		ISO9660)	WANT_FSCK=false
					mnt-fs "$devpart" "$mntpnt" $cdopts
					;;
		*)		warn "Unknown type <^B$fstype^b>.";				;;
	esac
} # }}}1
function simplify-disklabel { # {{{1
	local awkpgm
	awkpgm=$(</dev/stdin) <<-\
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
	as-root disklabel "$dev" | awk "$awkpgm"
} # }}}1
function mnt-drv { # {{{1
	local dev diskinfo fstype id label namefile newlabel part
	dev=$1
	id=${2:-}
	splitstr NL "$(simplify-disklabel)" diskinfo
	label=${diskinfo[0]}
	unset diskinfo[0]
	((${diskinfo[*]+1}))|| {
		warn "^B$dev^b is not formated for ^IOpenBSD^i."
		return
	  }
	set -A diskinfo -- "${diskinfo[@]}"
	label=${label%%+([[:space:]])}
	integer dc=${#diskinfo[*]}
	if ((dc == 1)); then
		part=${diskinfo%: *}
		fstype=${diskinfo#*: }
	elif [[ $dc -eq 10 && ${diskinfo[7]#  } == i:* ]]; then
		part=i
		fstype=MSDOS
	else
		warn 'Too many drives, bailing.'
		return 1
	fi
	gsub ' ' _ "$label" label

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
function disk-in-use { # {{{1
	for v in "${InUse[@]}"; do
		[[ $1 == $v:* ]]&& return
	done
	false
} # }}}1
function hd-devs-in-use { # {{{1
	local awkpgm
	awkpgm=$(</dev/stdin) <<-\
		\===AWKPGM===
		/^\// {
			sub(/^\/dev\//,"",$1)
			a[substr($1,1,3)]=1
	  	}
		END {
			for (v in a) print v
	  	}
		===AWKPGM===
	df -P | awk "$awkpgm"
} # }}}1
function main { # {{{1
	splitstr , "$(sysctl -n hw.disknames)" disknames
	set -A InUse -- $(hd-devs-in-use)
	for d in "${disknames[@]}"; do
		disk-in-use "$d" && continue
		desparkle "$d"
		notify "Trying to mount ^B$REPLY^b."
		mnt-drv "${d%%:*}" "${d#:}"
	done
} # }}}1

: ${USER:?}
needs as-root awk df egrep gsub needs-path

ffsopts='-t ffs -s -o rw,noexec,nodev,sync,softdep'
fatopts="-t msdos -s -o rw,noexec,nosuid,-g=$USER,-u=$USER"
cdopts="-t cd9660 -s -o rw,noexec,nosuid,-g"
ntfsopts="-t ntfs"

main; exit

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
