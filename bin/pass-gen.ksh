#!/bin/ksh
# @(#)[:77<S9x^E&Auq4>FM~cw6: 2017-10-21 19:15:39 Z tw@csongor]
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

: ${FPATH:?Run from within KSH}

defaultAlphabet=SNCL defaultSym='!"#$%&'\''()*+,./:;<=>?@[\]^_`{|}~'
integer defaultMin=13 defaultMax=19 defaultCount=7
integer minLen=-1     maxLen=-1     count=$defaultCount

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^IPassword Options^i^] ^[^IOutput Options^i^] ^[^IRetention Options^i^]
	         Generates passwords using ^B/dev/urandom^b
	       ^BPassword Options^b
	           ^[^T-n^t ^Umin len^u^] ^[^T-x^t ^Umax len^u^] ^[^T-a^t ^Ualphabet^u^] ^[^T-c^t ^Uhow many^u^]
	         The ^Balphabet^b argument can be:
	             ^US^u, ^Us^u, ^UP^u, or ^Up^u for symbols/punctuation^I*^i
	             ^UN^u, ^Un^u, ^UD^u, or ^Ud^u for numerals/digits
	             ^UC^u, ^Uc^u, ^UU^u, or ^Uu^u for capital/uppercase letters
	             ^UL^u, or ^Ul^u for lowercase letters
	           Upper case indicates the class is ^Irequired^i, lower it's ^Ioptional^i.
	           ^I*^iadditionally, any ^Iascii^i symbols or punctuation may be included
	            which will restrict the symbol class to those characters.
	           ^Bdefaults^b:
	             ^Umin len^u=^B$defaultMin^b, ^Umax len^u=^B$defaultMax^b ^Ualphabet^u=^B$defalutAlphabet^b ^Uhow many^u=^B$defaultCount^b
	       ^BOutput Options^b
	           ^T-q^t  Quiet, list generated passwords to ^Bstdout^b, nothing else.
	           ^T-v^t  Verbose, give some additional information.
	       ^BRetention Options^b
	           ^[^T-e^t ^Uemail address^u^] ^[^T-u^t ^Uuser name^u^] ^[^T-O^t ^Uid-type:id^u^] ^[^Udomain^u^]
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
alphabetIsSet=false
infoIsSet=false
integer requireLength=0
allowedChars=''
set -A requiredChars --
verbose=false
quiet=false
### process args helper functions

while getopts ':a:c:n:x:e:u:O:vqh' Option; do
	case $Option in
		a)  set-alphabet "$OPTARG";									;;
		c)  posint count "$OPTARG";									;;
		n)  posint minLen "$OPTARG";								;;
		n)  posint maxLen "$OPTARG";								;;
		e)  add-id 'eml' "$OPTARG";									;;
		u)  add-id 'usr' "$OPTARG";									;;
		O)  add-custom-id "$OPTARG";								;;
		v)  verbose=true;											;;
		q)  quiet=true;												;;
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

# wrap script guts in a function so edits to this script file don't 
# affect running instances of the script.
function main {

}

main "$@"; exit

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
