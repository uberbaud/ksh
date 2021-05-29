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
	^F{4}Usage^f: ^T$PGM^t ^[^Ulist_of_google_drives^u^]
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
want_accts_list=false
while getopts ':lh' Option; do
	case $Option in
		l)	want_accts_list=true;									;;
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
function list-accts { # {{{1
	local g
	for g in *; { [[ -d $g ]]&& print "    $g"; }
	exit
} # }}}1
function sync-drive { # {{{1
	grive "$@" && return 0
	warn "There were problems syncing ^S$1^s."
	return 1
} # }}}1
function do-one-drive { # {{{1
	local D dispD
	D="$GDRIVE/$1"
	desparkle "$1"
	dispD="$REPLY"
	[[ -d $D ]]|| die "No such account directory ^S$dispD^s."
	cd "$D" || die "Could not ^Tcd^t to ^S$dispD^s."

	if [[ -f .grive ]]; then
		notify "Syncing ^S$dispD^s."
		sync-drive
	else
		local ID='235587356455-5vcpjvn7nnocpbb3g31n2h9ouvv920bi.apps.googleusercontent.com'
		notify	"Syncing ^Bnew drive^b ^S$dispD^s."
		warn	'Before going to listed url, ^Blog in^b to account at'	\
				'    ^Shttps://accounts.google.com/ServiceLogin^s'		\
				'with user name'										\
				"    ^S$dispD^s"
		sync-drive --auth
	fi
} # }}}1

needs grive
[[ -d $GDRIVE ]]|| die "No such directory ^B$GDRIVE^b (^S\$GDRIVE^s)."
cd "$GDRIVE" || die "Could not ^Tcd^t to ^B$GDRIVE^b."

$want_accts_list && list-accts

(($#))|| set -- *

errs=0
for d { (do-one-drive "$d")|| ((errs++)) }; exit $errs

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
