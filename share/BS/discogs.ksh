#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2020-12-12,20.54.48z/5c6ed78>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

Qtype=NONE
TOKEN='EjJUNkQHcsEKJnZsDMMyOvZlxAsALNaBCoKCOQOq'
DISCOGS_UA='UberbaudDiscogsClient/0.1 +http://uberbaud.net'

# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^U-search_flag^u ^Usearch_term^u
	         Query the Discogs Music Database
	           ^T-s^t General search
	           ^T-p^t Pass through (eg: ^Tmasters/847447^t)

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
while getopts ':psh' Option; do
	case $Option in
		s)	Qtype=search;										;;
		p)	Qtype=passthrough;									;;
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
function get-it {
	local sterm= x extra=
	sterm=$1; shift
	for x { extra="$extra?$x"; }
#	print -r -- \
	curl													\
		--user-agent "${DISCOGS_UA:?}"						\
		https://api.discogs.com/"${sterm:?}&token=$TOKEN$extra"
}
PERL_PGM=
function url-encode {
	perl																\
		-E '$_=shift; s/[^[:alnum:]_~.-]/"%" . unpack("H*",$&)/ge; say'	\
		"${1:?}"
}
function qsearch {
	local sterm
	get-it "database/search?q=$(url-encode "${1:?}")"
}
# wrap script guts in a function so edits to this script file don't 
# affect running instances of the script.
function main {
	case $Qtype in
		search)	qsearch "$*";				;;
		passthrough) get-it "$@";			;;
		*)		die 'Need a search flag';	;;
	esac
}

main "$@"; exit

# Copyright (C) 2020 by Tom Davis <tom@greyshirt.net>.
