#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-11-20:tw/19.26.21z/8485b8>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}
REPO="NOTES"
SUFFIX=".note"

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t^[^T-a^t^] ^[^T-c^t^]
	         List all notes for a directory.
	           ^T-a^t  List ALL notes from everywhere!
	           ^T-c^t  Compact (don't list dates)
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
WANT_DATES=true
function bad_programmer {	# {{{2
	die 'Programmer error:'	\
		"  No getopts action defined for [1m-$1[22m."
  };	# }}}2
while getopts ':ach' Option; do
	case $Option in
		a)	REPO="${SYSDATA:?}/notes"; SUFFIX="";					;;
		c)	WANT_DATES=false;										;;
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

needs awk less sparkle

[[ -d $REPO ]]|| exit 0		#empty
cd $REPO || die 'Could not ^Tcd^t into ^B$REPO^b.'

IFS='
'
set -- $(/bin/ls *"$SUFFIX" 2>/dev/null|sort -n)
(($#))|| exit 0	#empty

integer i=0 x=0
for H; do
	if [[ -a $H ]]; then
		notes[i++]="$H"
	else
		badlinks[x++]="$H"
	fi
done

AWKPGM="$(</dev/stdin)" <<-\
	\===AWK===
		/<@\(#\)tag:/ {next}
		FNR == 2 && /^[0-9][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9].* Z/ {
				if (skipdate) {next}
				if (FNR != NR) { print "" }
				print "^B"$0"^b"
				next
			}
		# otherwise
			{print}
	===AWK===

function main {
	local s=1 pager SPARKLE_FORCE_COLOR
	$WANT_DATES && s=0

	if [[ -t 1 ]]; then
		pager="less -iMSx4 -FXc"
		SPARKLE_FORCE_COLOR=true
	else
		pager=cat
	fi

	awk -v skipdate=$s "$AWKPGM" "${notes[@]}"|sparkle #|$pager
	((x))&& warn "Bad links:" "${badlinks[@]}"
}
main; exit 0


# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
