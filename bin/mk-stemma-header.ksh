#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-11-25:18.42.31/tw/95b23a>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^Uoptions^u^]
	         Make a ^Uwhat^u and ^URFC4151 tag^u compatible stemma
	             ^I<marker+tag:machine.domain,date:user/timez/uniqrand>^i
	             ^T-H^t ^Udomain^u        defaults to ^T\${URI_AUTHORITY-\${EMAIL#*@}}^t
	             ^T-M^t ^Umachine name^u  defaults to ^T\${\$(uname -m)%.*}^t
	             ^T-D^t ^Uiso date^u      defaults to ^T\$(date -u +%Y-%m-%d)^t
	             ^T-T^t ^Utimez^u         defaults to ^T\$(date -u +%H.%M.%Sz)^t
	             ^T-U^t ^Uuser^u          defaults to ^T\$(id -n)^t
	         It is an error to specify a date or time but not both.
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
TIMEGIVEN=false
DATEGIVEN=false
while getopts ':H:M:D:T:U:h' Option; do
	case $Option in
		H)	[[ $OPTARG == [[:alnum:]]*(+([[:alnum:]-])[[:alnum:]])*(.[[:alnum:]]*(+([[:alnum:]-])[[:alnum:]])) ]]||
				die "Bad URI character in host name."
			H="$OPTARG"
			;;
		M)	[[ $OPTARG == [[:alnum:]]*(+([[:alnum:]-])[[:alnum:]]) ]]||
				die "Bad machine name characters." \
					"Expected [[:alnum:]-] not starting or ending with a dash."
			M="$OPTARG"
			;;
		D)	[[ $OPTARG == @(19|2[0-9])[0-9][0-9][/.-]@(0[1-9]|1[0-2])[/.-]@([0-2][0-9]|3[01]) ]]||
				die "Bad date format. Expected ^B%Y-%m-d^b."
			Dy="${OPTARG%%[/.-]*}"; OPTARG="${OPTARG#?????}"
			Dm="${OPTARG%[/.-]*}"; OPTARG="${OPTARG#???}"
			Dd="$OPTARG"
			((Dy>1969))|| die "Can only do dates after the epoch (1970)."
			DATEGIVEN=true
			;;
		T)	[[ $OPTARG == @([01][0-9]|2[0-3])[:.-][0-5][0-9][:.-]@([0-5][0-9]|60)?([Zz]) ]]||
				die "Bad time format (expected ^BHH.MM.SS^b, found ^B$OPTARG^b."
			Th="${OPTARG%%[[:punct:]]*}"; OPTARG="${OPTARG#???}"
			Tm="${OPTARG%[[:punct:]]*}"; OPTARG="${OPTARG#???}"
			Ts="${OPTARG%[Zz]}"
			TIMEGIVEN=true
			;;
		U)	[[ $OPTARG == +([[:alnum:]_.~-]|%[[:xdigit:]][[:xdigit:]]) ]]||
				die "Bad URI character in user name."
			U="$OPTARG"
			;;
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
(($#))&& die 'Too many nonflag parameters. Expected none.'

bins[0]='date'
bins[1]='random'
# we only need to find what we don't already have
[[ -n ${M:-} ]]|| bins[${#bins[*]}]='id'
[[ -n ${U:-} ]]|| bins[${#bins[*]}]='uname'
needs "${bins[@]}"

if $DATEGIVEN && $TIMEGIVEN; then
	DTs="$(date -ju +'%Y-%m-%d:%H.%M.%Sz' "$Dy$Dm$Dd$Th$Tm.$Ts" 2>/dev/null)" ||
		die "Bad date or time format."
	[[ $DTs == "$Dy-$Dm-$Dd:$Th.$Tm.$Ts"z ]]||
		die "Bad date or time values." "in:  $Dy-$Dm-$Dd:$Th.$Tm.$Ts""z" "out: $DTs"
elif $DATEGIVEN; then
	die 'If you give the date, you must also give the time.'
elif $TIMEGIVEN; then
	die 'If you give the time, you must also give the date.'
else
	DTs="$(date -u +'%Y-%m-%d:%H.%M.%Sz')"
fi

D="${DTs%:*}"
T="${DTs#*:}"

# Use the pid, but prefix it with 1–2 digits, and suffix it with 1
# digit, making the result unpredictable while maintaining uniqueness.
random -e 100;	A=$?; ((A))|| A='' # 0 prefix is octal, so don't
random -e 10;	B=$?
typeset -i16 X=$A$$$B
[[ -n ${M:-} ]]|| { M="$(uname -n)"; M="${M%.*}"; }
[[ -n ${U:-} ]]|| { U="$(id -un)"; }
[[ -n ${H:-} ]]|| { H="${URI_AUTHORITY-${EMAIL#*@}}"; }
: ${M-Neither URI_AUTHORITY nor EMAIL is set.}

#	'@' = \0100, '(' = \050, '#' = \043, ')' = \051
print -n '<\0100\050\043\051'"tag:$M.$H,$D:$U/$T/${X#?(-)16#}>"

# Copyright © 2017 by Tom Davis <tom@greyshirt.net>.
