#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-10-09:tw/18.53.32z/233fe01>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH} ${HOST:?}

backvol=/vol/gnar
backroot=$backvol/backups
backbase=$backroot/${HOST}
checkonly=false

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
	         Performs an ^Trsync^t backup to ^S$backbaseD^s.
	         ^T-c^t  Only ^Bcheck^b that the backup device is mounted."
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
while getopts ':ch' Option; do
	case $Option in
		c)	checkonly=true;											;;
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

needs awk egrep mount rsync

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
function main { # {{{1
	mount | egrep -q " $backvol " || die '^Bgnar^b is ^Bnot^b mounted.'
	[[ -d $backroot ]]|| die 'Required ^B$backroot^b path is missing.'
	$checkonly && {
		[[ -d $backbase ]]||
			warn "Missing host backup directory ^B$backbase^b."
		exit
	  }

	[[ -d $backbase ]]|| {
		warn "Creating missing host backup directory ^B$backbase^b."
		mkdir "$backbase" || die "Could not ^Tmkdir^t ^B$backbase^b."
	}

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
