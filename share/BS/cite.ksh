#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2020-12-22,16.28.09z/50a4e0f>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

die "Not implemented yet."

# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Create a bibliography from a url.
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
function get-the-html {
	curl -L --output the.html "$1" || die "Could not download."
}

function main {
	get-the-html "$1"

}

(($#<1))&& die "Missing required parameter ^Uurl^u."
(($#>1))&& die "Too many parameters. Expected only one (1)."

needs needs-cd

tempD=$(mktemp -d)
trap "rm -rf '$tempD'"	EXIT
print $tempD
needs-cd "$tempD"

main "$1"; exit

# Copyright (C) 2020 by Tom Davis <tom@greyshirt.net>.
