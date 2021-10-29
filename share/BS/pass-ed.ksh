#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2019-01-21:tw/06.25.20z/1191ef>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^Udomain^u
	         Edit the password record for a matching domain or unique
	         substring of a domain.
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

edit=${VISUAL:-${EDITOR:?'Neither $VISUAL nor $EDITOR is defined.'}}
needs "$edit"

secrets="${XDG_DATA_HOME:?}"/secrets
[[ -d $secrets ]]|| die 'No secrets directory.'

domain="$(pass-find "$@")" || die 'No matching ^Idomain^i found.'

"$edit" "$secrets/$domain.pwd"


# Copyright (C) 2019 by Tom Davis <tom@greyshirt.net>.
