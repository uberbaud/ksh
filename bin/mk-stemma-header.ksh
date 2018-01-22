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
	^F{4}Usage^f: ^T$PGM^t
	         Make a `what` compatible stemma header
	             ^Imarker+stemma+date+user@machine^i
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
while getopts ':h' Option; do
	case $Option in
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
(($#))&& die 'Too many arguments. Expected none.'

needs date id random uname

# Use the pid, but prefix it with 1–2 digits, and suffix it with 1
# digit, making the result unpredictable while maintaining uniqueness.
random -e 100;	A=$?; ((A))|| A='' # 0 prefix is octal, so don't
random -e 10;	B=$?
typeset -i16 X=$A$$$B
H="$(uname -n)"; H="${H%.*}"
DTs="$(date -u +'%Y-%m-%d:%H.%M.%Sz')"
D="${DTs%:*}"
T="${DTs#*:}"
I="$(id -un)"
U="${URI_AUTHORITY-${EMAIL#*@}}"
: ${U-Neither URI_AUTHORITY nor EMAIL is set.}

#	'@' = \0100, '(' = \050, '#' = \043, ')' = \051
print -n '<\0100\050\043\051'"tag:$H.$U,$D:$I/$T/${X#?(-)16#}>"

# Copyright © 2017 by Tom Davis <tom@greyshirt.net>.
