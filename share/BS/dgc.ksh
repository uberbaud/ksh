#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2019-11-19,23.28.47z/6eff7c>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[-D ^Ukey^u^T=^t^Uval^u^] ^Udgidl_file^u
	         DataGlue substitute (does nothing).
	           ^T-D^t  sets a ^Itext macro^i.
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
while getopts ':hD:' Option; do
	case $Option in
		D)	:;													;;
		h)	usage;												;;
		\?)	die "Invalid option: ^B-$OPTARG^b.";				;;
		\:)	die "Option ^B-$OPTARG^b requires an argument.";	;;
		*)	bad_programmer "$Option";							;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1

(($#))|| die 'Missing required DataGlue IDL input file.'
DGIDL=$1; shift
(($#))&& die 'Too many unflagged parameters. Expected one (1)'

die 'Sorry, not ^Byet^b implemented.' 						\
	'But if I were, I would have generated a file such as:'	\
	'^UReservations.pm^u'

# Copyright (C) 2019 by Tom Davis <tom@greyshirt.net>.
