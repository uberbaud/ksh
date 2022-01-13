#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2020-12-13,00.03.04z/414e624>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}
USER_AGENT='UberbaudMusicbrainzClient/0.1 +http://uberbaud.net'
MBRNZ='https://musicbrainz.org/ws/2'

# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Query the MusicBrainz music database.
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

function url-encode {
	perl	\
		-E '$_=shift; s/[^[:alnum:]_~.-]/"%" . unpack("H*",$&)/ge;say'	\
		"${1:?}"
}

# wrap script guts in a function so edits to this script file don't 
# affect running instances of the script.
function main {
	(($#))|| die 'Missing parameters'
#	print -r -- \
	curl --user-agent "${USER_AGENT:?}" \
		"$MBRNZ/recording?query=$(url-encode "$*")&fmt=json"
}

main "$@"; exit

# Copyright (C) 2020 by Tom Davis <tom@greyshirt.net>.
