#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-10-09:tw/18.53.32z/233fe01>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH} ${HOST:?}

fconfig=${XDG_CONFIG_HOME:?}/etc/backup-device
[[ -f $fconfig ]]||
	die "Missing configuration file ^S$fconfig^s."
IFS=: read diskname diskid <$fconfig ||
	die "Could not read configuration file ^$fconfig^s."
[[ -n $diskname ]]||	die "Could not read diskname."
[[ -n $diskid ]]||		die "Could not read diskid."

backvol=/vol/$diskname
backroot=$backvol/backups
backbase=$backroot/${HOST:?}
onlycheck_mounted=false
onlycheck_attached=false
stop_after_mount=false
quiet=false

desparkle "$backbase"
backbaseD="$REPLY"

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Performs an ^Trsync^t backup to ^S/vol/^Udisk name^u/backups/^U\$HOST^u^s
	         currently: ^S$backbaseD^s.
	         ^T-C^t  Only ^Bcheck^b that backup device ^S$diskid^s is plugged in.
	         ^T-c^t  Only ^Bcheck^b that the backup device is mounted
	             at ^S$backvol^s.
	         ^T-m^t  Mount backup device if not already mounted, but
	             don't perform backup.
	         ^T-q^t  Suppress availabilty failure messages.
	           ^GUses configuration file ^S$fconfig^s^g
	           ^Gwith one line formated ^Udisk name^u:^Udisk id^u.^g
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
while getopts ':cCmqh' Option; do
	case $Option in
		C)	onlycheck_attached=true;								;;
		c)	onlycheck_mounted=true;									;;
		m)	stop_after_mount=true;									;;
		q)	quiet=true;												;;
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
(($#))&& die 'Unexpected arguments.'

needs awk egrep mount rsync usb-mnt

rsync_opts="$(awk '{print $1}')" <<-\
	===
	--relative			# store with full path appended to destination
	--delete			# delete files on destination not on source
	--recursive			# recurse into directories
	--links				# copy symlinks AS symlinks
	--perms				# preserve permissions
	--keep-dirlinks		# use symlinks on dest if link is valid
	--times				# preserve modification times
	--group				# preserve groups
	--owner				# preserve owners
	--whole-file		# don't use delta-xfer (faster on local hd)
	===

function dieQuietly { #{{{1
	$quiet && exit 1
	die "$@"
} #}}}1
function Now { date -u +'%Y-%m-%d_%H:%M:%SZ'; }
function do-rsync { # {{{1
	notify 'BEGIN COPY'
	rsync $rsync_opts "$@" "$realhome" "$backto"
} # }}}1
function initial-backup { # {{{1
	set -A glob -- *
	[[ "${glob[*]}" == '*' ]]&&
		die "^B$backbaseD^b is not empty, but there is no link ^Scurrent^s."
	warn 'This appears to be the first backup of this device.' \
		 'Continuing will create a full copy of the current home'  \
		 'directory which could take some time.'
		 yes-or-no Continue || {
			echo '  ^EAborting^e' | sparkle
			exit 1
		  }
	do-rsync
} # }}}1
function standard-backup { # {{{1
	[[ -h $backbase/current ]]||
		die "^B$backbase/current^b is not a ^Slink^s."
	readonly lastback="$(readlink -fn $backbase/current)"
	[[ -n $lastback ]]|| die 'Could not find link for ^Ucurrent^u.'
	[[ -d $lastback ]]|| die '^Ucurrent^u does not link to a valid directory.'

	do-rsync --link-dest="$lastback"
	rm "$backbase"/current
} # }}}1
function check-attached { #{{{
	local allnames
	allnames="$(sysctl -n hw.disknames),"
	[[ $allnames == *:$diskid,* ]]||
		dieQuietly "Backup Device ^S$diskname^s is not attached."
	$onlycheck_attached && exit
	true
} #}}}1
function check-mounted { #{{{1
	local rc
	mount | egrep -q " $backvol "
	rc=$?
	$onlycheck_mounted && {
		(($rc))&&
			dieQuietly "Backup Device ^S$diskname^s is not mounted."
		exit $rc
	  }
	return $rc
} #}}}1
function try-mounting { #{{{1
	notify "Trying to mount ^S$diskname^s."
	usb-mnt
	check-mounted ||
		die "Could not mount ^S$diskname^s at ^S$backvol^s."
} #}}}1

function main { # {{{1
	check-attached
	check-mounted || try-mounting
	[[ -d $backbase ]]|| {
		warn "Creating missing host backup directory ^B$backbase^b."
		mkdir -p "$backbase" || die "Could not ^Tmkdir^t ^B$backbase^b."
	}
	$stop_after_mount && return

	splitstr : "$(getent passwd $(id -un))"
	readonly realhome="${reply[5]}"
	[[ -d $realhome ]]|| die "No HOME (^B$realhome^b) directory."
	cd "$realhome" || die "Could not ^Tcd^t to ^B$realhome^b."

	readonly timestamp="$(Now)"
	readonly backto="$backbase/$timestamp"
	[[ -d $backto ]]&&
		die "Backup directory ^B$backto^b already exists."

	notify "Starting: ^B$timestamp^b."

	mkdir "$backto" || die 'Could not create backup directory.'
	notify 'Creating subordinate directories.'
	mkdir -p $backto/$realhome || die 'Could not create ^S$HOME^s in backup dir.'

	if [[ -a $backbase/current ]]; then
		standard-backup
	else
		initial-backup
	fi
	notify 'END COPY' "Linking ^Bcurrent^b to ^B$timestamp^b."
	ln -fs "$backto" "$backbase/current"
	notify "Finished ^B$(Now)^b."
	notify 'Syncing disks'
	sync
	notify 'Done.'
} # }}}1

main "$@"; exit

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
