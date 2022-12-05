#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-08-07:tw/18.20.40z/26a3999>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

: ${FPATH:?Run from within KSH}

Prefix="  "

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t ^[^T-r^t^]
	         List accounts in ^Baccounts^b file
	           ^T-r^t  Lists in ^Iraw^i form (suitable for machine processing).
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
while getopts ':rh' Option; do
	case $Option in
		r)	Prefix='';												;;
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
					'warnOrDie is [1m${warnOrDie}[22m.'
	esac
} # }}}1

needs awk
fAccts=${XDG_CONFIG_HOME:?}/fetchmail/accounts
[[ -f $fAccts ]]|| -die "No such file [1m$fAccts[22m."

awkpgm="$(cat)" <<-\
	==AWK==
		/^[ \t]*;/	{ next }
		/^opts=/	{ next }
		/@/			{ print "$Prefix"\$1; next }
		/=/			{ print "$Prefix"\$1"@localhost"}
	==AWK==
awk -F'=' "$awkpgm" "$fAccts"

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
