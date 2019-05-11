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
		    PayPal (OpenBSD,WikiMedia,Guardian)
		    Google Payments
		
		    CSM
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
	# AWKPGM {{{1
	AWKPGM="$(cat)" <<-\
	\==AWK==
		BEGIN { FS="\t";i=0 }
		NF == 2 { a[i]=$2; i++ }
		{
			total+=$3;
			sub( / +$/, "", $2 );
			if ($1 == "*")	{ printf( "     *  " ) }
			else			{ printf( "    %0.2d  ", $1 ) }
			printf( "%-24s", $2 );
			if (NF == 3) { printf( "    %8.2f", $3 ) }
			printf("\n");
		  }
		END {
				lmarg="                     ";
				dash=lmarg;
				gsub(/ /,"=",dash);
				printf( "  "dash"==============================================\n" );
				printf( "  "lmarg"  TOTAL      %8.2f", total );
				if (i>0) {
					printf( " (" );
					for (A in a) str=str",+"a[A];
					sub(/,/,"",str);
					printf( "%s)\n", str );
				  }
		  }
	==AWK==
	# END AWKPGM }}}1

	#data format
	# dom TAB Creditor OPT-SPACE [TAB RECUR-AMT]
	awk "$AWKPGM" <<-\
	==DATA==
		04	WikiMedia               	3.00
		09	Duke Energy
		10	Chase
		10	Guardian                	3.00
		18	Hulu                    	7.99
		18	OpenBSD Foundation      	10.00
		18	UNC Public Television   	5.00
		20	Spectrum                	65.99
		28	GitHub                  	7.00
		28	CSM                     	11.00
		*	FP (28-01)              	2.39
	==DATA==
fi

# Copyright (C) 2018 by Tom Davis <tom@greyshirt.net>.
