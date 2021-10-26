#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2021-10-15,23.05.23z/5819158>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

LOG=~/log/panera-eLarn.log
TAB='	' # < capture tab
NL='
' # ^capture newline

# RECORD LAYOUT
readonly ndxDate=0 ndxStart=1 ndxStop=2 ndxDur=3 ndxNote=4

DRYRUN=false
# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM start^t^|^Tstop^t^|^[^T-n^t^] ^Tsum^t^
	         Keep a record of Panera out-of-schedule e-learning.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
function bad_programmer { # {{{2
	die 'Programmer error:'	\
		"  No getopts action defined for [1m-$1[22m."
} # }}}2
while getopts ':nh' Option; do
	case $Option in
		n)	DRYRUN=true;										;;
		h)	usage;												;;
		\?)	die "Invalid option: ^B-$OPTARG^b.";				;;
		\:)	die "Option ^B-$OPTARG^b requires an argument.";	;;
		*)	bad_programmer "$Option";							;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
function require-stop-timestamp { # {{{1
	local lineno=$1 stop=${4-} duration=${5-}
	[[ -n $stop ]]||
		die 'Missing ^Sstop^s time in last record.' "^Gline:^g ^B$lineno^b."
	[[ -n $duration ]]||
		die 'Missing ^Sduration^s in last record.' "^Gline:^g ^B$lineno^b."
} # }}}1
function isRECORD { # {{{1
	[[ $1 == 20[0-9][0-9]-@(0[1-9]|1[012])-[0-3][0-9]$TAB+([0-9])* ]]
} # }}}1
function handle-start { # {{{1
	local F lineno=$1 line=$2 comment=$3
	isRECORD "$line" && {
			splitstr "$TAB" "$line"  F
			require-stop-timestamp $lineno "${F[@]}"
		  }
		gsub % %% "$comment" dCOMMENT
		date +"%Y-%m-%d${TAB}%s$TAB$TAB$TAB$dCOMMENT" >>$LOG
} # }}}1
function handle-stop { # {{{1
	local F lineno=$1 line=$2 comment=$3 start stop duration
	isRECORD "$line" ||
		die 'Missing ^Sstart^s record.' "line: $lineno"
	splitstr "$TAB" "$line" F
	[[ -n ${F[ndxStop]:-} ]]&&
		die 'Missing ^Sstart^s record.' "line: $lineno"

	start=${F[ndxStart]:-}
	stop=$(date +%s)
	duration=$((stop-start))
	((duration > 86400))&&
		die '^Sstart^s record was more than 24 hours ago.' "line: $((i+1))"
	comment=${F[ndxNote]:-}/${comment-}
	comment=${comment#/} # Trim slash if F[ndxNote] was empty
	comment=${comment%/} # Trim slash if COMMENT was empty
	Lines[i]="${F[ndxDate]}$TAB$start$TAB$stop$TAB$duration$TAB$comment"
	c=0
	l=${#Lines[*]}
	while ((c<l)); do print -r -- "${Lines[c]}"; ((c++)); done >$LOG
} # }}}1
function sum-out { print -r -- "--- $1"; }
function make-hr { # {{{1
	local n=80

	[[ -t 1 ]]&& n=$(tput columns)
	((n-=8))
	print -n -- '    '
	while ((n--)); do print -rn -- '─'; done
} # }}}1
function print-lines-from { # {{{1
	local n total L ln D B E T N hr

	n=$(($1-1))
	total=$2
	L=${#Lines[*]}
	hr=$(make-hr)

	print -- "\n\t   When\t     Duration\tWhat\n$hr"
	while ((++n<L)); do
		ln=${Lines[n]}
		isRECORD "$ln" && print -- "$ln"
	done | while IFS="$TAB" read D B E T N; do
		print -- "\t$D   $(s2hms $T)\t$N"
	done
	print -- "$hr\n\t     \033[1mTOTAL   $total\033[0m\n"
} # }}}1
function handle-sum { # {{{1
	local c l A old new F mark
	c=0
	l=${#Lines[*]}
	A=0
	mark=0
	while ((c<l)); do
		L="${Lines[c]}"
		case $L in
			\#*) :; ;;
			---*)
				old=${L##+([!0-9:])}
				mark=$((c+1))
				new=$(s2hms $A)
				[[ $old == $new ]]||
					warn "Bad sum on line $c"
				A=0
				;;
			*)
				if isRECORD "$L"; then
					splitstr "$TAB" "$L"  F
					require-stop-timestamp $((i+1)) "${F[@]}"
					((A+=${F[3]}))
				else
					warn "Bad record on line ^B$c^b."
				fi
				;;
		esac
		((c++))
	done
	# only append a SUM LINE if it isn't zero
	if ((A)); then
		hms=$(s2hms $A)
		print-lines-from $mark $hms
		! $DRYRUN && sum-out "$hms" >>$LOG
	else
		notify "$old (previous sum)"
	fi
} # }}}1
(($#))||	die 'Expected an argument of ^Tstart^t, ^Tstop^t, or ^Tsum^t.'

typeset -l s=${1:-}	# make it lowercase
shift

[[ $s == @(start|stop|sum) ]]||
	die "Needed arg of ^Tstart^t^|^Tstop^t^|^Tsum^t^"

COMMENT="$*"

needs splitstr

splitstr "$NL" "$(<$LOG)" Lines

i=${#Lines[*]}
((i--))	# index is zero based, so the last index is the array size less one.

# skip backward past any comments until we have a data row
while [[ ${Lines[i]} == \#* ]]; do ((i--)); done

# do the specific sub-command
case ${s-} in
	start)	handle-start $((i+1)) "${Lines[i]}" "$COMMENT";	;;
	stop)	handle-stop  $((i+1)) "${Lines[i]}" "$COMMENT";	;;
	sum)	handle-sum;										;;
esac

true # end on a good note

# Copyright (C) 2021 by Tom Davis <tom@greyshirt.net>.
