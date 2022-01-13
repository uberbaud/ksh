#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-08-11:tw/04.49.36z/23cefa>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset; : ${FPATH:?Run from within KSH}
needs date

typeset -- calOpts='' daysAfter=1 daysBefore=0
set -A justnow -- $(date +'%s %e %b %Y')
typeset -i TS=${justnow[0]} DOM=${justnow[1]} YEAR=${justnow[3]}
typeset -l -L 3 MON=${justnow[2]}
typeset -- yearOnly=false withWeek=false

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t ^[^T-w^t^|^T-y^t^] ^[^T-A^t ^Unum^u^] ^[^T-B^t ^Unum^u^] ^[^Uyear^u^] ^[^Umonth_name^u^] ^[^Uday^u^]
	         Wrapper and pretty formatter for ^Tcal^t and ^Tcalendar^t
	         ^T-w^t      Display week numbers too.
	         ^T-y^t      Display whole year (no ^Tcalendar^t output).
	         ^T-A^t ^Unum^u  Show events for ^Udays^u after.
	         ^T-B^t ^Unum^u  Show events for ^Udays^u before.
	         Date bits can be in any order. Unspecified bits will use today's bits.
	       ^T${PGM} -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
while getopts ':wyA:B:h' Option; do
	case $Option in
		w)	calOpts="$calOpts -w"; withWeek=true;					;;
		y)	yearOnly=true; calOpts="$calOpts -y";					;;
		A)	daysAfter=$OPTARG;										;;
		B)	daysBefore=$OPTARG;										;;
		h)	usage;													;;
		\?)	die USAGE "Invalid option: ^B-$OPTARG^b.";				;;
		\:)	die USAGE "Option ^B-$OPTARG^b requires an argument.";	;;
		*)	bad-programmer "No getopts defined for ^T$Option^t.";	;;
	esac
done
# remove already processed arguments
shift $(($OPTIND - 1))
# ready to process non '-' prefixed arguments
# /options }}}1
integer LAST_EVENT=0
function +evlist { # {{{1
	for e { evlist[LAST_EVENT++]="$e"; }
} # }}}1

[[ $daysAfter == *[!0-9]* ]]&&	die '-A requires a number of days.'
[[ $daysBefore == *[!0-9]* ]]&&	die '-B requires a number of days.'

(($#>3))&& die 'Too many arguments.'
if (($#==1)) && [[ $1 == [0-9][0-9][0-9][0-9] ]]; then
	calOpts="$calOpts $1"
	yearOnly=true
	shift
elif (($#)); then
	typeset -l o
	for o; do
		case $o in
			[0-9][0-9][0-9][0-9])
				YEAR=$o
				;;
			[0-9][0-9]|[0-9])
				DOM=$o
				;;
			@(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)*)
				MON=$o
				;;
			*)
				desparkle $o
				die "Unparseable parameter ^B$REPLY^b."
				;;
		esac
	done
	calOpts="$calOpts $MON $YEAR"
fi

# ───────────────────────────────────────────────────── GET CALENDAR ───
cal=/usr/bin/cal
needs $cal sed

search="\\<($DOM)\\>"; ((DOM<10))&& search=" $search"
replace='[48;5;147m&[0m'
splitstr NL "$($cal $calOpts 2>&1 | sed -E -e "s/$search/$replace/g")" cal

#remove last line if it's blank
l=$((${#cal[*]}-1))
[[ ${cal[l]} == *( ) ]]&& unset cal[l]

# with options, don't do the events bit
$yearOnly && { printf ' %s\n' "${cal[@]}"; exit 0; }

# ─────────────────────────────────────────────────────── GET EVENTS ───
needs calendar resize
eval $(resize -u)
months='jan feb mar apr may jun jul aug sep oct nov dec'
t=${months%$MON*}
typeset -Z 2 MM=$(((${#t}/4)+1)) DOM
((YEAR<1970))&& {
	printf "\e[48;5;222m%${COLUMNS}s\r %s\e[49m\n"	\
	'' 'WARNING: [1mcalendar[22m can'\''t deal with years before [1m1970[22m'		\
	'' "         So for events, we're using [1m1970[22m instead of [1m$YEAR[22m."	\
	'' "         The calendar itself uses [1m$YEAR[22m."
	YEAR=1970
}
useDate="$YEAR$MM$DOM"

evblob=$(calendar -A $daysAfter -B $daysBefore -t $useDate) ||
	die 'Problem with ^Tcalendar^t.'

# ──────────────────────────────────────────── FORMAT events listing ───
calSize=20 # standard cal output (20 columns)
$withWeek && ((calSize+=5))
evsize=$((COLUMNS-(calSize+5))) # adding various gutters and borders

# we use the saved epoch TimeStamp just in case we passed midnight 
# during the intervenning time. Unlikely though that may be.
TODAY=$(date -r $TS +'%b %d ')
TOMORROW="$(date -r $((TS+86400)) +'%b %d ')"

expectday=''
nt='
	' # <<< NEWLINE,TAB
gsub "$nt" ' ' "$evblob" evblob  # deformat multiline events
splitstr NL "$evblob" calevs
for ln in "${calevs[@]}"; do
	splitstr TAB "$ln" tuple
	[[ ${tuple[0]:-} == $expectday ]]|| {
		expectday=${tuple[0]}
		case "$expectday" in
			"$TODAY")		+evlist '[1m   today[22m';		;;
			"$TOMORROW")	+evlist '[1m   tomorrow[22m';	;;
			*)				+evlist "[1m   $expectday[22m";	;;
		esac
	  }
	# remove extraneous spaces
	unset tuple[0]; set -A tuple -- ${tuple[*]}
	ev=${tuple[*]}
	if [[ $ev == *BIRTHDAY ]]; then
		H='[38;5;241;48;5;225m'; E='[48;5;128;38;5;226m 🎂 [0m'
		ev="${ev%BIRTHDAY} "
	else
		H=''; E=''
	fi
	# break lines according to whitespace and terminal size
	word=''; line=''
	while ((${#ev})); do
		word=${ev%% *}
		ev=${ev#"$word"}"; ev="${ev# } # remove word and POSSIBLY space
		((${#line}+${#word}>evsize))&& {
			+evlist "$H${line# }$E"
			line='   '
		  }
		line="$line $word"
	done
	[[ -n ${line# } ]]&& +evlist "$H${line# }$E"
done

# ───────────────────────────────── VERTICALLY CENTER cal and events ───
unset l
integer cS=0 cE=$((${#cal[*]}-1)) eS=0 eE=$((${#evlist[*]}-1)) last=0 l2=0
if ((cE<eE)); then
	last=eE
	((l2=(eE-cE)/2,cS+=l2,cE+=l2))
else
	last=cE
	((l2=(cE-eE)/2,eS+=l2,eE+=l2))
fi

# ──────────────────────────────────────────────────────────── PRINT ───
# the ANSI sequence \e[#G moves to the absolute column #

if ((LINES>last)); then
	pager=cat
else
	pager=less
fi

integer i=-1 cI=0 eI=0
fmt=" %-${calSize}s  %s\n"
while ((i++<last)); do
	cLn=''; eLn=''
	(((cS<=i)&&(i<=cE)))&& cLn=${cal[cI++]}
	(((eS<=i)&&(i<=eE)))&& eLn=${evlist[eI++]}
	printf "$fmt" "$cLn" "$eLn"
done | $pager

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
