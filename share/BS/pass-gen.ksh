#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-10-21:tw/19.15.39z/3671b8>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

upper=ABCDEFGHIJKLMNOPQRSTUVWXYZ
lower=abcdefghijklmnopqrstuvwxyz
digit=0123456789
punct='!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~'
mob_punct='~|&_./'
mob_max=9
mob_upper=ABCDEFGHJKLMNPQRSTUVWXYZ
mob_lower=abcdefghijkmnopqrstuvwxyz
mob_digit=23456789

defaultAlphabet=SNCL;	symbols=''
integer defaultMin=13	defaultMax=19	minLen=-1	maxLen=-1	count=3
integer reqLen=0

# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^IPassword Options^i^] ^[^IOutput Options^i^] ^[^IRetention Options^i^]
	         Generates passwords using ^B/dev/urandom^b
	       ^BPassword Options^b
	           ^[^T-n^t ^Umin_len^u^] ^[^T-x^t ^Umax_len^u^] ^[^T-a^t ^Ualphabet^u^] ^[^T-s^t ^Usymbols^u^] ^[^T-c^t ^Uhow_many^u^]
	           ^[^T-d^t^] adds some dashes and sets default alphabet to NCL
	           ^[^T-m^t^] sets ^T-x ^B$mob_max^b^t
	         The ^Balphabet^b argument can be:
	             ^US^u, ^Us^u, ^UP^u, or ^Up^u for symbols/punctuation^I*^i
	             ^UN^u, ^Un^u, ^UD^u, or ^Ud^u for numerals/digits
	             ^UC^u, ^Uc^u, ^UU^u, or ^Uu^u for capital/uppercase letters
	             ^UL^u, or ^Ul^u for lowercase letters
	           Upper case indicates the class is ^Irequired^i, lower it's ^Ioptional^i.
	           ^Bdefaults^b:
	             ^Umin_len^u=^B$defaultMin^b, ^Umax_len^u=^B$defaultMax^b ^Ualphabet^u=^B$defaultAlphabet^b ^Uhow_many^u=^B$count^b ^Usymbols^u=^I$symbols^i
	       ^BOutput Options^b
	           ^T-q^t  Quiet, list generated passwords to ^Bstdout^b, nothing else.
	           ^T-v^t  Verbose, give some additional information.
	       ^BRetention Options^b
	           ^[^T-r^t^] ^[^T-e^t ^Uemail_address^u^] ^[^T-u^t ^Uuser_name^u^] ^[^T-O^t ^Uid-type:id^u^] ^[^Udomain^u^]
	           ^T-r^t  Updates (resets) existing password and any id info.
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
updatePassword=false
alphabetIsSet=false;	infoIsSet=false
allowUC=false;   allowLC=false;   allowSYM=false;   allowDIG=false
requireUC=false; requireLC=false; requireSYM=false; requireDIG=false
dashify=false
integer requireLength=0
quiet=false
### process args helper functions
function set-alphabet { #{{{2
	$alphabetIsSet &&
		die '^BAmbiguous^b: ^Ualphabet^u is set more than once.'
	local options=$1
	[[ -n $options ]]|| die '^Ualphabet^u cannot be empty.'

	while [[ -n $options ]]; do
		case "$options" in
			[SP]*)	requireSYM=true;		;;
			[sp]*)	allowSYM=true;			;;
			[ND]*)	requireDIG=true;		;;
			[nd]*)	allowDIG=true;			;;
			[CU]*)	requireUC=true;			;;
			[cu]*)	allowUC=true;			;;
			L*)		requireLC=true;			;;
			l*)		allowLC=true;			;;
			*)		desparkle "${options%${options#?}}"
					die "Unknown alphabet specifier ^U$REPLY^u."
					;;
		esac
		options=${options#?}
	done

	# do this after processing the class specifiers in case a user 
	# passed any more than once
	$requireSYM	&& ((reqLen++))
	$requireDIG	&& ((reqLen++))
	$requireUC	&& ((reqLen++))
	$requireLC	&& ((reqLen++))

	alphabetIsSet=true
} #}}}2
function posint { #{{{2
	[[ $2 == +([0-9]) ]]||
		die "^U$1^u MUST be a positive decimal integer."
	eval "$1=$2"
} # }}}2
NEXT_IDS_ID=0
function add-id { #{{{2
	ids[NEXT_IDS_ID++]="$1: $2"
	infoIsSet=true
} #}}}2
function add-custom-id { #{{{2
	[[ $1 == :* ]]&& die "Bad custom format for ^B$1^b, missing ^Bkey^b."
	[[ $1 == *:* ]]|| die "Bad custom format for ^B$1^b, missing ^Bvalue^b."
	add-id "${1%%:*}" "${1#*:}"
} #}}}2

use_mobile=false
while getopts ':a:c:dn:x:e:u:O:s:qmrh' Option; do
	case $Option in
		a)  set-alphabet "$OPTARG";									;;
		c)  posint count "$OPTARG";									;;
		d)  dashify=true;											;;
		n)  posint minLen "$OPTARG";								;;
		x)  posint maxLen "$OPTARG";								;;
		e)  add-id 'eml' "$OPTARG";									;;
		u)  add-id 'usr' "$OPTARG";									;;
		O)  add-custom-id "$OPTARG";								;;
		s)  symbols=$OPTARG;										;;
		q)  quiet=true;												;;
		m)  posint maxLen $mob_max; use_mobile=true;				;;
		r)	updatePassword=true;									;;
		h)	usage;													;;
		\?)	die "Invalid option: [1m-$OPTARG[22m.";				;;
		\:)	die "Option [1m-$OPTARG[22m requires an argument.";	;;
		*)	bad_programmer "$Option";								;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments

$use_mobile && {
	upper=$mob_upper
	lower=$mob_lower
	digit=$mob_digit
	[[ -n $symbols ]]|| dashify=true
}

[[ -n $symbols ]]&& {
	$quiet || {
		[[ $symbols == +([[:punct:]]) ]]||
			warn 'Non-punctuation characters included by ^T-s^t.'
	  }
	punct=$symbols
  }

$dashify && $alphabetIsSet && {
	$requireSYM || $allowSYM &&
		die '^T-d^t conflicts with ^T-s^t ^O*[^o^TSs^t^O]*^o' \
			'dashify cannot be used with an alphabet containing symbols/punctuations'
}
$alphabetIsSet || set-alphabet "$defaultAlphabet"
$dashify && {
	requireSYM=false
	allowSYM=false
  }

# max MUST come before min so that -1 won't be kept for min
((maxLen == -1))&& {
	maxLen=$minLen
	((maxLen<defaultMax))&& maxLen=$defaultMax
  }

((minLen == -1))&& {
	minLen=$maxLen
	((defaultMin<minLen))&& minLen=$defaultMin
  }

((minLen <= maxLen))|| die '^Uminimum^u MUST be less than ^Bmaximum^b.'
((reqLen<=maxLen))||
	die 'There are more ^Brequired^b characters than ^Umax_len^u allows.'
((reqLen<minLen))|| minLen=$reqLen

# /options }}}1

umask u=rw,go=
needs cut random umenu xclip new-array umask

(($# <= 1 ))|| die 'Too many arguments. Expected one (1).'
typeset -l domain=''
(($#))&& domain=$1

if $infoIsSet; then
	[[ -n $domain ]]|| die '^Udomain^u is required to ^Brecord^b ^Uinfo^u.'
elif $updatePassword; then
	[[ -n $domain ]]|| die '^Udomain^u is required to ^Bupdate^b password.'
elif [[ -n $domain ]]; then
	die '^Uemail_addr^u, ^Uuser_name^u, or some other ^Uid^u must be supplied' \
		'when saving to ^Udomain^u.pwd'
fi

pwdFile=${XDG_DATA_HOME}/secrets/$domain.pwd
if $updatePassword; then
	[[ -a $pwdFile ]]|| die 'Password file for ^B$domain^b does not exists.'
else
	[[ -a $pwdFile ]]&& die 'Password file for ^B$domain^b already exists.'
fi

allowed=''
$allowSYM || $requireSYM	&& allowed="$allowed$punct"
$allowDIG || $requireDIG	&& allowed="$allowed$digit"
$allowUC  || $requireUC		&& allowed="$allowed$upper"
$allowLC  || $requireLC		&& allowed="$allowed$lower"

function random-char { #{{{1
	random -e ${#1}
	R="$(print -r "$1" | cut -c $(($?+1)))"
} #}}}1
function add-random-char { #{{{1
	integer n=0
	random-char "$2"
	while :; do
		random -e $1
		n=$?
		[[ -n ${rstr[n]:-} ]]&& continue
		rstr[n]="$R"
		break
	done
} #}}}1

new-array results
integer range=$((maxLen-minLen)) thisLen=0 dashCount=0 lastDash=0 dashWhen=3
while ((count--)); do
	set -A rstr --
	lastDash=1
	((!range))|| random -e $range
	thisLen=$((minLen+$?))
	$requireSYM	&& add-random-char $thisLen "$punct"
	$requireDIG	&& add-random-char $thisLen "$digit"
	$requireUC	&& add-random-char $thisLen "$upper"
	$requireLC	&& add-random-char $thisLen "$lower"
	for i in $(jot $thisLen 0); do
		[[ -n ${rstr[i]:-} ]]&& continue
		if $dashify && ((++lastDash == dashWhen))then
			R=-
			lastDash=0
		else
			random-char "$allowed"
		fi
		rstr[i]="$R"
	done
	+results "$(printf '%s' "${rstr[@]}")"
done

results-not-empty || die 'Weirdly, ^S$results^b is empty.'

function show-ids { #{{{1
	for ln; do print -r -- "$ln"; done
} #}}}1
function new-file { #{{{1
	local File
	File=$1; shift
	notify "It is also saved in ^B$File^b."
	show-ids "$@" | tee -a "$File"
} #}}}1
function update-file { #{{{1
	die 'Unimplemented'
} # }}}1


if $quiet; then
	printf "%s\n" "${results[@]}"
else
	### choose a password from those generated
	password=$(umenu "${results[@]}")
	[[ -n $password ]]|| die 'No information saved.'

	print -n "$password" | xclip -selection clipboard -in
	notify 'Your new ^Bpassword^b has been copied to the ^Bclipboard^b.'
	add-id 'pwd' "$password"
	if [[ -n $domain ]]; then
		if $updatePassword; then
			update-file "$pwdFile" "${ids[@]}"
		else
			new-file "$pwdFile" "${ids[@]}"
		fi
	else
		show-ids "${ids[@]}"
	fi
fi


# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
