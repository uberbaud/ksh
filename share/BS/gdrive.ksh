#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-10-06:tw/22.10.55z/1a38826>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

GDRIVE=$HOME/hold/gdrive

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^Ulist of google drives^u^]
	         Sync given Google Drives.
	           If no list of drives is given, all drives are synced.
	           Drives are those in ^S$GDRIVE^s.
	       ^T$PGM -l^t
	         List available drives
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
list_accts=false
while getopts ':lh' Option; do
	case $Option in
		l)	list_accts=true;										;;
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

function list-accts {
	for g in *; { [[ -d $g ]]&& print "    $g"; }
	exit
}

function sync-drive {
	grive "$@" && return 0
	warn "There were problems syncing ^S$1^s."
	return 1
}

function one-drive {
	D="$GDRIVE/$1"
	desparkle "$1"
	dispD="$REPLY"
	[[ -d $D ]]|| {
		warn "No such account directory ^S$dispD^s."
		return 1
	  }

	cd "$D" || {
		warn "Could not ^Tcd^t to ^S$dispD^s."
		return 1
	  }
	if [[ -f .grive ]]; then
		notify "Syncing ^S$dispD^s."
		sync-drive
	else
		notify	"Syncing ^Bnew drive^b ^S$dispD^s."
		warn	'Before going to listed url, ^Blog in^b to account at'
				'    ^Shttps://accounts.google.com/ServiceLogin^s'
				'with user name'
				"    ^S$dispD^s"
		sync-drive --auth
	fi
}

function main {
	[[ -d $GDRIVE ]]|| die "No such directory ^B$GDRIVE^b (^S\$GDRIVE^s)."
	cd "$GDRIVE" || die "Could not ^Tcd^t to ^B$GDRIVE^b."
	$list_accts && list-accts
	needs grive

	(($#))|| set -- *
	for d; do
		[[ -d $GDRIVE/$d ]]|| continue
		one-drive "$d"
	done
}

main "$@"; exit $?

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
