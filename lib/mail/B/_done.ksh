#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-08-08:tw/00.26.18z/127495>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t
	         Save the important bits and clean out the inbox.
	       ^T${PGM} -h^t
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
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
function expire-old-mail { # {{{1
	print -nu2 ' [34m>>>[0m [1mDeleting[0m old trash ... '
	if pick -before -30 +deleted -seq expired 2>/dev/null; then
		rmm -unlink expired
	else
		print -- '^Gnothing to delete.^g' | sparkle
	fi
} # }}}1
function Done { # {{{1
	[[ -z $(flist +inbox -sequence marked -fast -noshowzero) ]]
} # }}}1

needs flist folder forceline mark pick refile rmm yes-or-no

# clean out groupmail list
GROUPMAIL=${MMH:?}/groupmail
[[ -e $GROUPMAIL ]]&& { [[ -w $GROUPMAIL ]]|| chmod u+w "$GROUPMAIL"; }
: >$GROUPMAIL

(($#))|| set a # 'a' is for 'all'
mark "$@" +inbox -sequence marked 2>/dev/null
folder +inbox

Done && { printf '  Nothing to do.\n'; return; }

exec 3>${HOME:?}/log/msg-done

local M='\e[34m' P=' >>>' C='\e[0m' B='\e[1m' S='\e[35m'

printCheckMsg()		printf "$M$P$B Checking$S %s$C ... "		"$1" >&2
printRefileMsg()	printf "    $B Refiling$C messages.\n"		"$1" >&2
printSkipMsg()		printf "skipping (no matching messages).\n"	"$1" >&2
function X { # {{{1
	local filter=$1 pattern=$2 box=$3 msg=$4

	printCheckMsg "$msg"
	pick marked +inbox "$filter" "$pattern" -sequence picked 2>/dev/null
	if (($?)); then
		printSkipMsg "$msg"
	else
		printRefileMsg "$msg"
		refile picked -src +inbox +"$box"
	fi
	Done && {
		local F="$M$P$B Skipping $S %s$C (no more messages)"
		eval "function X { printf '$F' \"\$4\"; }"
	  }
} # }}}1

expire-old-mail
D_TO=--delivered-to

# X  Key    Pattern                        mailbox       message
# ─ ─────  ─────────────────────────────  ────────────  ───────────────
  X -from  '@yt\.lan'                     yt.lan        '@yt.lan'
  X -from  'root@csongor\.lan'            root@csongor  '@csongor'
  X $D_TO  'bgumm102@gmail\.com'          notes         'Notes to Self'
  X -to    'source-changes@openbsd\.org'  obsd-cvs      'OpenBSD CVS'
  X -from  '@stackoverflow\.'             stackover     'Stack Overflow'
CIP='alexepstein@industrialprogress.net'
  X -from  "$CIP"                         energy        'CIP'
  X -from  '@receipt\.lowes\.com'         receipts      "Lowe's receipt"
SQR='messenger@messaging\.squareup\.com'
  X -from  "$SQR"                         receipts      "Square receipt"
  X -subj  'receipt'                      receipts      "other receipt"
  X -from  'permies@permies.com'          permies       "permies"
  X -from  '@paypal\.com'                 paypal        "paypal"
TAXES='@efile\.jacksonhewitt\.com'
  X -from  "$TAXES"                       taxes         "tax related"

if Done; then
    print -u2 ' [34m>>>[0m No messages to [1mremove[0m.'
else
    print -u2 ' [34m>>>[0m [1mTrashing[0m everything else.'
    refile marked -nolink -src +inbox +deleted
fi

MAILTEMP="${XDG_PUBLICSHARE_DIR:?}/mail"
set -A files2delete "$MAILTEMP"/*
if [[ $files2delete != *\* ]]; then
    print -u2 ' [34m>>>[0;1m Cleaning[0m mail workshop.'
    yes-or-no 'Delete the mail parts which maybe you'\''re using' &&
        rm "${files2delete[@]}"
fi

# the MMH `show` litters `mhpath +` with temp files, get rid of them
rm -f $(mhpath +)/show?????? >/dev/null 2>&1

exec 3>&-

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
