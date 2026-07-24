#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-10-09:tw/18.00.11z/24a1e93>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: "${FPATH:?Run from within KSH}"

# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-n^t^] ^[^Udev^u^]^[^T:^t^Upartition list^u^]^[^T/^t^Uname^u^] ^S…^s
	         Mount any unmounted but attached USB devices.
	           ^T-f^t  Don't do otherwise automatic ^Bfsck^b.
	         If ^Udev^u is given, only that drive will be mounted.
	         ^Upartition list^u is a comma separated list of partitions to mount.
	         ^Uname^u is the name of the directory in ^T/vol^t where the file system
	         will be mounted. If ^Udev^u is not specified but a ^Upartition list^u, or
	         ^Uname^u is given, and there is more than one unmounted drive, none
	         will be mounted.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
function bad_programmer {	# {{{2
	die 'Programmer error:'	\
		"  No getopts action defined for ^B-$1^b."
  };	# }}}2
WANT_FSCK=true
while getopts ':nh' Option; do
	case $Option in
		n)	WANT_FSCK=false;										;;
		h)	usage;													;;
		\?)	die "Invalid option: ^B-$OPTARG^b.";				;;
		:)	die "Option ^B-$OPTARG^b requires an argument.";	;;
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
	desparkle "$dev" dDev
	notify "Trying to mount ^B$dDev^b."
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
		[[ $part == ${PARTITION:-$part} ]]|| {
			warn "^T-p $PARTITION^t given, but the only PARTITION is ^B$part^b."
			return
		  }
		PARTITION=
	elif [[ -n ${PARTITION} ]]; then
		local p
		part=
		for p in "${diskinfo[@]}"; do
			[[ ${p%: *} == $PARTITION ]]|| continue
			part=$PARTITION
			fstype=${p#*: }
		done
		[[ -n $part ]]||
			warn "^T-p $PARTITION^t given but not found." "${diskinfo[@]}"
	elif [[ $dc -eq 10 && ${diskinfo[7]#  } == i:* ]]; then
		part=i
		fstype=MSDOS
	else
		warn 'Too many drives, bailing.' "${diskinfo[@]}"
		warn 'Use ^T-p^T ^Upartition^u to select a PARTITION to mount.'
		return 1
	fi
	gsub ' ' _ "$label" label

	label=$label${PARTITION:+_$PARTITION}
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
function list-unmounted-devices { # {{{1
	splitstr , "$(sysctl -n hw.disknames)" disknames list
	set -A InUse -- $(hd-devs-in-use)
	for d in "${disknames[@]}"; do
		disk-in-use "$d" && continue
		list=${list:+"$list "}$d
	done
	print -n -- "${list:-}"
} # }}}1
function ensure-dev-name-is-valid { # {{{1
	local want dev duid drvstr
	want=$1
	for drvstr in ${drives[*]:+"${drives[@]}"}; do
		dev=${drvstr%:*}
		duid=${drvstr#$dev}; duid=${drvstr#:} # in two in case no :duid
		[[ $want == $dev || $want == $duid ]]&& return
	done
	false
} # }}}1
function main { # {{{1
	local O device plist mnt_name
	splitstr , "$(sysctl -n hw.disknames)" drives

	# If no drives were given, mount all unmounted drives
	(($#))|| set -- $(list-unmounted-devices)

	# for all given (if any) OR for all unmounted (if none given)
	for O; do
		device=${O%%[:/]*}
		ensure-dev-name-is-valid "$device" || {
			warn "Did not find mountable drive ^B$device^b"
			continue
		  }
		O=${O#"$device"}
		[[ $O == :* ]]&& {
			O=${O#:}
			plist=${O%*/}
			O=${O#"$plist"}
		  }
		[[ $O == /* ]]&& {
			mnt_name=${O#/}
		  }
		mnt-drv "$device" "${plist:-}" "${mnt_name:-}"
	done

} # }}}1

: ${USER:?}
needs as-root awk df egrep gsub needs-path splitstr

ffsopts='-t ffs -s -o rw,noexec,nodev,sync,softdep'
fatopts="-t msdos -s -o rw,noexec,nosuid,-g=$USER,-u=$USER"
cdopts="-t cd9660 -s -o rw,noexec,nosuid,-g"
ntfsopts="-t ntfs"

#		[[ $OPTARG == [abd-p] ]]||
#			die "Invalid ^Upartition^u (valid ^O[^o^Tabd-p^t^O]^o)."
#		PARTITION=${PARTITION:+$PARTITION }$OPTARG

main; exit

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
