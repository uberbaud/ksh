#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-08-22:tw/00.39.08z/1a956be>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH} ${XDG_DATA_HOME:?}
needs awk

# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t ^Upattern^u
	         Gets email addresses matching the arguments.
	       ^T${PGM} -h^t
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

emailf=${SYSDATA:?}/emails.tsv
[[ -f $emailf ]]|| die "Can't find the email file."

gsub [[:punct:]] '.*' "$*"		# no punctuation
typeset -l pattern=$REPLY		# lower case bits

[[ -z $pattern ]]&&			return 1
[[ $pattern == '.*' ]]&&	return 1
pattern='(^| )'"$pattern"

awkpgm=$(</dev/stdin) <<-\
	==AWK==
	{
		l=tolower(\$1);				# match lower case bits
		gsub("[[:punct:]]]]","",l)	# no punctuation
	}
	l~/$pattern/ {print "\""\$1"\" <"\$2">"}
	==AWK==

awk -F'\t' "$awkpgm" "$emailf"


# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
