#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2018-03-21:tw/17.30.36z/53c3bf0>
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
	         Get and display information about an available syspatch.
	         Does not apply the patch. Use ^Tsyspatch^t for that.
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

needs w3m xnotify
(($#))&& die 'Unexpected arguments. Wanted none.'

plan_b_path=/var/plan-b
needs-path -or-die $plan_b_path

announce=$plan_b_path/syspatch.announce
[[ -s $announce ]]||	exit 0 # a change to nothing

# set -- $(<$announce)
# (($#))|| die 'Did not get the patch names.'

msg='SYSPATCH: Available Syspatchen'
errata="https://www.openbsd.org/errata$(uname -r|tr -d .).html"

xnotify "$msg See: $errata"

# Copyright (C) 2018 by Tom Davis <tom@greyshirt.net>.
