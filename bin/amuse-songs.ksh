#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2019-11-26,03.54.13z/12e32a8>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

which=full

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-r^t^]
	         Show song info.
	         ^T-r^t  raw vtags output.
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
while getopts ':rh' Option; do
	case $Option in
		r)	which=raw;											;;
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
function warnOrDie { #{{{1
	case $warnOrDie in
		die)  die "$@" 'Use [1m-f22m to force an edit.';		;;
		warn) warn "$@";											;;
		*)    die '[1mProgrammer error[22m:' \
					'warnOrDie is [1m${warnOrDie}[22m.';		;;
	esac
} # }}}1

(($#))|| die 'Missing required search pattern'

needs amuse:get-workpath sql-reply

amuse:get-workpath
SQL "ATTACH '$REPLY/amuse.db3' AS amuse;"

function show-raw {
	SQL <<-==SQLITE==
	SELECT file, kind, label, value
	  FROM amuse.vtags
	 WHERE value LIKE '%$1%'
	     ;
	==SQLITE==
	sql-reply
}

function show-full {
	SQL <<-==SQLITE==
	SELECT id, performer || '/' || album || '/' || track || '-' || song
	  FROM vsongs
	 WHERE id IN (
		 SELECT file
		  FROM amuse.vtags
		 WHERE value LIKE '%$1%'
		)
	 ORDER BY performer, album, track
		;
	==SQLITE==
	sql-reply
}


for W { show-$which $W; }; exit


# Copyright (C) 2019 by Tom Davis <tom@greyshirt.net>.
