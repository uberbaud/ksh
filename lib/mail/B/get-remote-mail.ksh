#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2022-10-12,22.18.38z/b19d62>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

MARGIN=4
nomail='\033[35mnone\033[39m'
MAIL_CFG_DIR=${XDG_CONFIG_HOME:?}/mail
this_pgm=${0##*/}
LOGFILE=${this_pgm%%.*}
TAB='	'
OPATH=$PWD
L=$OPATH/L

# Usage {{{1
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle-path "$L"
	dL=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Do downloads simulateously.
	         ^T-l^t  Log to ^T$HOME/log/$LOGFILE^t.
	         ^T-d^t  Capture some debug info to $dL
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
LOGIT=false
[[ -n ${DEBUG:-} ]]&& LOGIT=true
DEBUG=${DEBUG:+true}
while getopts ':ldh' Option; do
	case $Option in
		d)	DEBUG=true;														;;
		l)	LOGIT=true;														;;
		h)	usage;															;;
		\?)	die USAGE "Invalid option: ^B-$OPTARG^b.";						;;
		\:)	die USAGE "Option ^B-$OPTARG^b requires an argument.";			;;
		*)	bad-programmer "No getopts action defined for ^T-$Option^t.";	;;
	esac
done
[[ -z ${DEBUG:-} ]]&& DEBUG=false
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
function status-update { # {{{1
	: ${1:?} ${2:?} ${3:?}
	$LOGIT && log $LOGFILE "$3"
	print -r -- "$1	$2	$3"
} # }}}1
function fetchrc-file-exists { # {{{1
	local sGet sSkip

	[[ -f $1 ]]&&		return 0	# we're good to go
	[[ -f SKIP/$1 ]]&&	return 1	# skip it

	# neither option was true, so give a warning which returns 1
	sparkle-path "$PWD";		sGet=$REPLY
	sparkle-path "$PWD/SKIP";	sSkip=$REPLY
	warn "Could not find ^B$1^b in either" "$sGet, or" "$sSkip."
} # }}}1
function logit { # {{{1
	print -r -- "$1:$TAB$2" >>$OPATH/log
} # }}}1
function debugcapture { # {{{1
	print -r -- "$2" >>$L.$1
} # }}}1
function do-one-acct { # {{{1
	local acct=${1:?} row=${2:?} msg ln dscr
	local -i10 new=0 got=0

	fetchrc-file-exists "$acct" || return 1

	$DEBUG && : >$L.$row
	status-update "$row" "$MARGIN" "\033[1;36m$acct\033[22;39m"
	fetchmail -f ./$acct --pidfile ./$acct.pid 2>$OPATH/log.$row.err |
		while IFS= read -r ln; do
			$dbg $row "$acct$TAB$ln"
			[[ $ln == *\ fetchmail:* ]]|| {
				logit "$acct" "$ln"
				$dbg $row "$TAB$TAB:BAD"
				continue
			  }
			dscr=${ln#* fetchmail:}
			dscr=${dscr##+([[:space:]])}

			$dbg $row "$TAB$TAB$dscr"
			if [[ $dscr == reading* ]]; then
				((got+=1))
				msg="$got/$new"
				$dbg $row "$TAB$TAB:got"
			elif [[ $dscr == +([0-9])\ message* ]]; then
				new=${dscr%% *}
				[[ $dscr == *seen\)* ]]&& {
					seen=${dscr%seen\)*}
					seen=${seen##*\(}
					new=$((new-seen))
				  }
				if ((new)); then
					msg="0/$new"	# 0 of some downloaded
				else
					msg=$nomail		# none OR all seen
				fi
				$dbg $row "$TAB$TAB:new $new"
			elif [[ $dscr == 'No mail for '* ]]; then
				msg="$nomail"
				$dbg $row "$TAB$TAB:nomail"
			else
				logit "$acct" "$ln"
				msg="error"
				$dbg $row "$TAB$TAB:error"
			fi
			status-update "$row" "$INFOPOS" "$msg"
		done
	[[ -s $OPATH/log.$row.err ]]|| rm -f $OPATH/log.$row.err
	status-update "$row" "$MARGIN" "$acct"
} # }}}1
function async-download { # {{{1
	typeset -i10 i=0
	for acct; do
		i=$((i+1))
		do-one-acct $acct $i &
	done
	wait
} # }}}1
function main { # {{{1
	$DEBUG && : >$L
	$LOGIT && rotate-logfiles "$HOME/log/$LOGFILE"
	async-download "$@" | while IFS='	' read -r ln col msg; do
		print -- "\033[$((top+ln));${col}H$msg"
	done
	$DEBUG && {
		cat $L.+([0-9]) >$L
		rm -f $L.+([0-9])
	  }
} # }}}1
function setup-screen { # {{{1
	local maxlen l acct

	eval "$(resize)"
	((LINES<$#))&& warn "Screen is too short, will be fudged."
#	tput clear

	maxlen=0
	for acct; do
		l=${#acct}
		((maxlen<l))&& maxlen=$l
	done
	INFOPOS=$((maxlen+(MARGIN*2)))
} # }}}1
function show-errors { # {{{1
	set -- $OPATH/log.+([0-9]).err
	[[ $1 == *+* ]]&& return
	for l; do
		h3 "$l"
		cat "$l"
	done
} # }}}1

needs needs-cd needs-file fetchmail i-can-haz-inet get-row-col use-app-paths \
	rotate-logfiles log

i-can-haz-inet || die "$REPLY"

if $DEBUG; then
	dbg=debugcapture
else
	dbg=:
fi

use-app-paths mail
needs-cd -or-die "$MAIL_CFG_DIR"
[[ .LAST_UPDATED -ot accounts ]]&& mail-update-accts.ksh

needs-cd -or-die "fetchmail"
(($#))|| {
	set -- *@*.*
	[[ $1 == *\* ]]&& die "No accounts to download."
  }

setup-screen "$@"
trap 'tput cnorm' EXIT
tput civis
notify "Fetching ^Bremote^b mail"

top=$(get-row-col)
top=${top% *}

main "$@"; print -- "\033[$(($#+top+1));1H"; show-errors; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
