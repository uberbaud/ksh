#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2018-03-15:tw/00.07.55z/137de68>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

DUPLEX=true; ECON=false; FIT=false; MANUAL=false; RAW=false; REVERSE=false
COPIES=1; RANGES=

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^Uoptions^u^] ^[^Ufile1^u ^S…^s^]
	         Prints files or stdin to poco.
	           ^BBoolean options^b
	             ^Tduplex^t*, ^Teconomy^t, ^Tfit-to-page^t, ^Tmanualfeed^t, ^Traw^t, and ^Treverse^t
	             May be prefixed with ^Tno^t, ^Tnot-^t, or suffixed with ^T=^t^Ibool^i,
	             where ^Ibool^i is one of ^Ton^t, ^Tyes^t, or ^Ttrue^t; or ^Toff^t, ^Tno^t, or ^Tfalse^t.
	               ^Iduplex^i is ^Itrue^i by default, all others are ^Ifalse^i.
	           ^BOther options^b
	             ^Tcopies=^t^Iinteger^i
	             ^Tpage-ranges=^t^Iranges^i where ^Iranges^i is something like ^U1,3-5,16^u.
	             ^Tpages=^t^Iranges^i same as page-ranges.
	           Additional options may be specified with ^T-o ^Uopt^u^t.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
new-array opts
# process -options {{{1
function bad_programmer {	# {{{2
	die 'Programmer error:'	\
		"  No getopts action defined for [1m-$1[22m."
  };	# }}}2
while getopts ':o:h' Option; do
	case $Option in
		o)	+opts -o "$OPTARG";									;;
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
needs lpr
function boolvar { # {{{1
	local B=true O=$1
	[[ $O == no?(t)?(-)* ]]&& { B=false; O="${O##no?(t)?(-)}"; }
	[[ $O == *=* ]]&& {
		local N=${O%%=*}
		typeset -l Ob=${O#*=}
		O=$N
		if [[ $Ob == @(on|yes|true) ]]; then
			if $B; then B=true; else B=false; fi
		elif [[ $Ob == @(off|no|false) ]]; then
			if $B; then B=false; else B=true; fi
		else
			desparkle "$Ob"
			die "Unknown boolean value ^T$REPLY^t."
		fi
	}
	case $O in
		duplex)			DUPLEX=$B;							;;
		economy)		ECON=$B;							;;
		fit-to-page)	FIT=$B;								;;
		manual)			MANUAL=$B;							;;
		manualfeed)		MANUAL=$B;							;;
		raw)			RAW=$B;								;;
		reverse)		REVERSE=$B;							;;
		*)				return 1;							;;
	esac
	return 0
} #}}}1
function isopt { # {{{1
	case "$1" in
		copies=+([0-9]))
			+opts -# "${1#copies=}"
			;;
		copies?(=*))
			die '^Bcopies^b expects an integer.'
			;;
		page?(-range)s=+([0-9])?(-+([0-9]))*(,+([0-9])?(-+([0-9]))))
			+opts -o "page-ranges=${1#*=}"
			;;
		page?(-range)s?(=*))
			die '^Bpage-ranges^b expects a range like ^U1,3-5,16^u.'
			;;
		*)
			boolvar "$1"
			;;
	esac
} # }}}1

while (($#)) && isopt "$1"; do shift; done

if $DUPLEX; then
	+opts -o sides=two-sided-long-edge
else
	+opts -o sides=one-sided
fi
$ECON		&& +opts -o JCLEconomode=On
$FIT		&& +opts -o fit-to-page
$MANUAL		&& +opts -o InputSlot=ManualFeed
$RAW		&& +opts -o raw
$REVERSE	&& +opts -o outputorder=reverse

opts-not-empty && set -- "${opts[@]}" "$@"

print -u2 lpr "$@"
lpr "$@"


# Copyright (C) 2018 by Tom Davis <tom@greyshirt.net>.
