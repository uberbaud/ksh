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
function bail-if-not-audio-file { # {{{1
	NOT-IMPLEMENTED
} # }}}1
function convert-to-ogg-if-not-already-ogg { # {{{1
	NOT-IMPLEMENTED
} # }}}1
function get-hash-name-from-ogg { # {{{1
	# Get new name from
	#   ckSum=$(oggdec -QRo - $OLDFILE | cksum -a sha384b)
	#   fName=${ckSum#?}
	#   fPath=${ckSum%"$fName"}
	NOT-IMPLEMENTED
} # }}}1
function verify-ogg-isnt-already-amusified { # {{{1
	# INSERT INTO files (pcm_sha384b,hertz,channels,encoding,duration)
	#   …
	# INSERT INTO vtags
	NOT-IMPLEMENTED
} # }}}1
function add-info-to-db { # {{{1
	# Hardlink (if originally ogg) OR mv (if converted) to
	#   $AMUSE_DATA_HOME/$fPath/$fName
	NOT-IMPLEMENTED
} # }}}1
function mv-ogg-to-amuse-repository { # {{{1
	NOT-IMPLEMENTED
} # }}}1
function do-safe-unzip { # {{{1
	NOT-IMPLEMENTED
	# print tempdir holding all files
} # }}}1
function do-one-file { # {{{1
	local MUSIC_FILE=$1
	(do-steps)
} # }}}1
function do-one-item { # {{{1
	local f REPLY
	[[ -f $1 && $1 == *.zip ]]&&
		set -- $(do-safe-unzip)

	if [[ -f $1 ]]; then
		do-one-file "$1"
	elif [[ -d $1 ]]; then
		for f in "$1"/*; do
			[[ -f $f ]]&& do-one-file "$f"
		done
	else
		warn "^B$1^b is neither a ^Ifile^i nor a ^Idirectory^i."
	fi
} # }}}1

use-steps

+ get-all-mediainfo						warn
+ bail-if-not-audio-file				false
+ convert-to-ogg-if-not-already-ogg		warn
+ get-hash-name-from-ogg				warn
+ verify-ogg-isnt-already-amusified		false
+ add-info-to-db						warn
+ mv-ogg-to-amuse-repository			warn

for F { do-one-item "$F"; }; exit

# Copyright (C) 2020 by Tom Davis <tom@greyshirt.net>.
