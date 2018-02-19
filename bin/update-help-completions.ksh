#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-11-29:tw/15.38.36z/238b7da>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH} ${KDOTDIR:?}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Updates $KDOTDIR/completions/help
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


HELPF=$KDOTDIR/completions/help
TEMPF=$HELPF.tmp

printf "%s\n" $KDOTDIR/help/* $KDOTDIR/functions/*	\
	| sed -e 's+.*/++' -e '/\*$/d'					\
	| sort											\
	| uniq											\
	> $TEMPF

cmp -s $HELPF $TEMPF || { 
	cat $TEMPF >$HELPF
	print help # for Makefile output
  }

rm $TEMPF

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
