#!/bin/ksh
# @(#)[:x*SCYViRoZ!;;Xv&jEya: 2017-08-22 00:39:08 Z tw@csongor]
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

: ${FPATH:?Run from within KSH} ${XDG_DATA_HOME:?}
needs awk

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
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
function warnOrDie { #{{{1
	case $warnOrDie in
		die)  die "$@" 'Use [1m-f22m to force an edit.';		;;
		warn) warn "$@";											;;
		*)    die '[1mProgrammer error[22m:' \
					'warnOrDie is [1m${warnOrDie}[22m.';		;;
	esac
} # }}}1

emailf=$XDG_DATA_HOME/sysdata/emails.tsv
[[ -f $emailf ]]|| die "Can't find the email file."

gsub [[:punct:]] '.*' "$*"		# no punctuation
typeset -l pattern="$REPLY"		# lower case bits

[[ -z $pattern ]]&&			return 1
[[ $pattern == '.*' ]]&&	return 1
pattern='(^| )'"$pattern"

awkpgm="$(cat)" <<-\
	==AWK==
	{
		l=tolower(\$1);				# match lower case bits
		gsub("[[:punct:]]]]","",l)	# no punctuation
	}
	l~/$pattern/ {print "\""\$1"\" <"\$2">"}
	==AWK==

awk -F'\t' "$awkpgm" "$emailf"


# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
