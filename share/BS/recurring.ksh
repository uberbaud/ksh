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

TAB='	'
[[ -n ${SYSDATA:-} ]]|| die '^S$SYSDATA^s is not set.'
fDATA=$SYSDATA/recurring
[[ -f $fDATA ]]|| die "Could not find ^B^S\$SYSDATA^s/recurring^b."

print
if $ALT; then
	while IFS=$TAB read date payto from amt; do
		[[ ${date:-#} == \#* ]]&& continue
		[[ $from == @(wells|) ]]&& print $payto
		[[ $from == @(paypal) ]]&& {
			PAYPAL="${PAYPAL:-},${payto%%+([[:space:]])}"
		  }
	done <$fDATA
	[[ -n $PAYPAL ]] && PAYPAL=" (${PAYPAL#,})";
	print "PayPal$PAYPAL"
else
	# AWKPGM {{{1
	AWKPGM="$(</dev/stdin)" <<-\
	\==AWK==
		BEGIN { FS="\t";i=0 }
		/^(#|--|$)/ {next}
		{
			total+=$4;
			sub( / +$/, "", $2 );
			if ($1 == "*")	{ printf( "     *  " ) }
			else			{ printf( "    %0.2d  ", $1 ) }
			printf( "%-24s", $2 );
			if (NF == 4) { printf( "    %8.2f", $4 ) }
			else         { a[i]=$2; i++ }
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
	awk "$AWKPGM" $fDATA
fi

# Copyright (C) 2018 by Tom Davis <tom@greyshirt.net>.
