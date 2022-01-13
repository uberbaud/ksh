#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2020-01-17,22.30.55z/32551f0>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^Umusic_file^u ^S…^s
	         Hardlink ogg file (or convert in to) to amuse directory, and
	         update database with relevant information.
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

function do-one-file {
	# Convert file to ogg if necessary
	# Get new name from
	#   ckSum=$(oggdec -QRo - $OLDFILE | cksum -a sha384b)
	#   fName=${ckSum#?}
	#   fPath=${ckSum%"$fName"}
	# Compare info if already exists
	# OR, Hardlink (if originally ogg) OR mv (if converted) to
	#   $AMUSE_DATA_HOME/$fPath/$fName
	# -----
	# INSERT INTO files (pcm_sha384b,hertz,channels,encoding,duration)
	#   …
	# INSERT INTO vtags
}

function do-one-item {
	if [[ -f $1 ]]; then
		do-one-file "$1"
	elif [[ -d $1 ]]; then
		for F in "$1"/*; do
			do-one-item "$F"
		done
	else
		warn "^B$1^b is neither a ^Ifile^i nor a ^Idirectory^i."
	fi

}

for F { do-one-item "$F"; }; exit

# Copyright (C) 2020 by Tom Davis <tom@greyshirt.net>.
