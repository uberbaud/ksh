#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-08-08:tw/00.26.18z/127495>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
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
function expire { # {{{1
	pick -before -30 +deleted -seq expired &&
		rmm -unlink expired
	forceline
} # }}}1
function Done { # {{{1
	[[ -z "$(flist +inbox -sequence marked -fast -noshowzero)" ]]
} # }}}1

needs flist folder forceline mark pick refile rmm yes-or-no

# clean out groupmail list
: >"$NMH"/groupmail

(($#))|| set all
mark "$@" +inbox -sequence marked 2>/dev/null
folder +inbox

Done && { printf '  Nothing to do.\n'; return; }

exec 3>${HOME:?}/log/msg-done

local M='\e[34m' P=' >>>' C='\e[0m' B='\e[1m' S='\e[35m'

printCheckMsg()		printf "$M$P$B Checking$S %s$C ... "		"$1" >&2
printRefileMsg()	printf "    $B Refiling$C messages.\n"		"$1" >&2
printSkipMsg()		printf "skipping (no matching messages).\n"	"$1" >&2
function X { # {{{1
	local filter="$1" pattern="$2" box="$3" msg="$4"

	printCheckMsg "$msg"
	pick marked +inbox "$filter" "$pattern" -sequence picked 2>/dev/null
	if (($?)); then
		printSkipMsg "$msg"
	else
		printRefileMsg "$msg"
		refile picked -unlink -src +inbox +"$box"
	fi
	Done &&
		function X { printf "$M$P$B Skipping $S %s$C (no more messages)"; }
} # }}}1

# X  Key    Pattern                        mailbox       message
# ─ ─────  ─────────────────────────────  ────────────  ───────────────
  X -from  '@yt\.lan'                     yt.lan        '@yt.lan'
  X -from  'root@csongor\.lan'            root@csongor  '@csongor'
  X -to    'bgumm102@gmail\.com'          notes         'Notes to Self'
  X -to    'source-changes@openbsd\.org'  obsd-cvs      'OpenBSD CVS'
  X -from  '@stackoverflow\.'             stackover     'Stack Overflow'

print -nu2 ' [34m>>>[0m [1mDeleting[0m old trash. ... '
expire 2>/dev/null

if Done; then
    print -u2 ' [34m>>>[0m No messages to [1remove[0m.'
else
    print -u2 ' [34m>>>[0m [1mTrashing[0m everything else.'
    refile marked -unlink -src +inbox +deleted
fi

set -A files2delete ${XDG_CACHE_HOME:?}/mail/*
if [[ $files2delete != *\* ]]; then
    print -u2 ' [34m>>>[0;1m Cleaning[0m mail workshop.'
    yes-or-no 'Delete the mail parts which maybe you'\''re using' &&
        rm "${files2delete[@]}"
fi

exec 3>&-

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
