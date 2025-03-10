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
	^F{4}Usage^f: ^T$PGM^t ^Upattern^u
	         List matching mail accounts and passwords for an account or
	         an ^BSQL^b ^TLIKE^t ^Upattern^u  of one or more accounts. If ^Upattern^u
	         does not contain a ^'^T%^t^' or ^'^T?^t^' the pattern will be matched as
	         ^T%^t^Upattern^u^T%^t. If ^Upattern^u begins with an exclaimation mark ^(^T!^t^),
	         the search will be negated.
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
function do-query { # {{{1
	if [[ -n $ACCT ]]; then
		[[ $ACCT == *[\?%]* ]]|| ACCT="%$ACCT%"
		SQLify ACCT
	fi
	WHERE=${ACCT:+ WHERE username ${NOT:-} LIKE $ACCT}
	sqlite3 "$maildb" <<-===SQL===
	.headers off
	.mode column
	SELECT username, password FROM accounts${WHERE:-};
	===SQL===
} # }}}1
function main { # {{{1
	local ACCT NOT
	ACCT=${1:-}
	[[ $ACCT == !* ]]&& {
		ACCT=${ACCT#!}
		NOT='NOT'
	}
	do-query | sed -Ee 's/^/  /'
} # }}}1
(($# > 1))&& die 'Too many arguments. Expected at most one (1).'

needs needs-path needs-file sqlite3 SQLify

mailcfg=${XDG_CONFIG_HOME:?}/mail
needs-path -or-die "$mailcfg"

maildb=$mailcfg/mailcfg.db3
needs-file -or-die "$maildb"

main "$@"; exit

# Copyright (C) 2021 by Tom Davis <tom@greyshirt.net>.
