#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2018-07-08:tw/03.54.41z/19af785>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-x^t^]
	         Print current bill amounts.
	           ^T-x^t  print organizations who need contact updates.
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
ALT=false
while getopts ':xh' Option; do
	case $Option in
		x)	ALT=true;											;;
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
function warnOrDie { #{{{1
	case $warnOrDie in
		die)  die "$@" 'Use [1m-f22m to force an edit.';		;;
		warn) warn "$@";											;;
		*)    die '[1mProgrammer error[22m:' \
					'warnOrDie is [1m${warnOrDie}[22m.';		;;
	esac
} # }}}1

print
if $ALT; then
	sparkle <<-\
	==SPARKLE==
		    Amazon
		    PayPal (OpenBSD,WikiMedia)
		    Google Payments
		
		    Hulu
		    Spectrum
		    GitHub
		    GoDaddy
		
		    Walgreens
		
		    UNC Public Television
		    FP
		    Libertarian Party
	==SPARKLE==
else
	sparkle <<-\
	==SPARKLE==
		    03  Duke Energy
		    04  WikiMedia                    3.00
		    10  Chase New Card
		    14  Chase Old Card
		    18  Hulu                         8.55
		    18  OpenBSD Foundation          10.00
		    18  UNC Public Television        5.00
		    20  Spectrum                    44.99
		    28  GitHub                       7.00
		
		    *   FP (28-01)                   2.39
		
		                       TOTAL        80.93 (+Chase,+Duke)
	==SPARKLE==
fi
print

# Copyright (C) 2018 by Tom Davis <tom@greyshirt.net>.
