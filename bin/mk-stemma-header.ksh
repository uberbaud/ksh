#!/bin/ksh
# @(#)[:lVwc|Iba@n^kl!T`!&gj: 2017-11-25 18:42:31 Z tw@csongor]
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


needs date id printf random uname

# Use the pid, but prefix it with 1–2 digits, and suffix it with 1
# digit, making the result unpredictable while maintaining uniqueness.
random -e 100;	A=$?
random -e 10;	B=$?
typeset -i16 X=$A$$$B

#	'@' = \x40, '(' = \x28, '#' = \x23, ')' = \x29
printf '\x40\x28\x23\x29[tag:%s.%s,%s/%s/%s]'	\
	"$(uname -n)"								\
	"${URI_AUTHORITY?}"							\
	"$(date -u +'%Y-%m-%d:%H.%M.%S')"			\
	"$(id -un)"									\
	"${X#?(-)16#}"

# Copyright © 2017 by Tom Davis <tom@greyshirt.net>.
