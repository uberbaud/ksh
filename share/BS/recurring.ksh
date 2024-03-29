#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2018-07-08:tw/03.54.41z/19af785>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-x^t^]
	         Print current bill amounts.
	           ^T-e^t  Edit the file first.
	           ^T-x^t  Print organizations who need contact updates.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
ALT=false
EDIT=false
while getopts ':exh' Option; do
	case $Option in
		e)	EDIT=true;														;;
		x)	ALT=true;														;;
		h)	usage;															;;
		\?)	die "Invalid option: ^B-$OPTARG^b.";							;;
		\:)	die "Option ^B-$OPTARG^b requires an argument.";				;;
		*)	bad-programmer "No getopts action defined for ^T-$Option^t.";	;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1

needs needs-file

TAB='	'
[[ -n ${SYSDATA:-} ]]|| die '^S$SYSDATA^s is not set.'
fDATA=$SYSDATA/recurring
needs-file -or-die "$fDATA"

$EDIT && {
	V=$HOME/bin/ksh/v
	needs-file -or-die $V
	$V "$fDATA"
  }

print
if $ALT; then
	while IFS=$TAB read date payto from amt; do
		[[ ${date:-#} == \#* ]]&& continue
		[[ $from == @(wells|) ]]&& print $payto
		[[ $from == @(paypal) ]]&& {
			PAYPAL=${PAYPAL:-},${payto%%+([[:space:]])}
		  }
	done <$fDATA
	[[ -n $PAYPAL ]] && PAYPAL=" (${PAYPAL#,})";
	print "PayPal$PAYPAL"
else
	# AWKPGM {{{1
	AWKPGM=$(</dev/stdin) <<-\
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
