#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2021-05-23,04.21.29z/366f748>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^Uregex^u
	         List matching mail accounts and passwords for an account or
	         an ^Tawk^t ^Uregex^u of one or more accounts.
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
(($# > 1))&& die 'Too many arguments. Expected at most one (1).'
ACCT=${1:-.}

secrets=${XDG_DATA_HOME:?}/secrets
[[ -d $secrets ]]|| die 'No secrets directory'

mailaccts=$secrets/mail-accounts
[[ -f $mailaccts ]]|| die 'Could not find ^Smail-accounts^s file.'
[[ -r $mailaccts ]]|| die 'Can not read ^Smail-accounts^s file.'

needs awk

AWKPGM=$(</dev/stdin) <<-\
	==AWK==
	/^[[;]/				{ next }			# skip comments and headers
	/^[[:space:]]*$/	{ next }			# skip blank lines
	/^\*/				{ sub( /./, "" ) }	# remove mark
	# otherwise
	/$ACCT/				{ print }
	==AWK==

awk "$AWKPGM" "$mailaccts"; exit

# Copyright (C) 2021 by Tom Davis <tom@greyshirt.net>.
