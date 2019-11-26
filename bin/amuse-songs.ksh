#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2019-11-26,03.54.13z/12e32a8>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

which=full
list=false

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-r^t^|^T-l^t^] ^UsqlPattern^u
	         Show or edit list of songs matching ^%^UsqlPattern^u^%.
	         ^T-l^t  list, do not edit.
	         ^T-r^t  raw vtags output (implies ^T-l^t).
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
while getopts ':lrh' Option; do
	case $Option in
		l)	list=true;											;;
		r)	which=raw; list=true;								;;
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
	 WHERE value LIKE $1
	     ;
	==SQLITE==
	sql-reply ''
}

function show-full {
	SQL <<-==SQLITE==
	SELECT id, performer || '/' || album || '/' || track || '-' || song
	  FROM vsongs
	 WHERE id IN (
		 SELECT file
		  FROM amuse.vtags
		 WHERE value LIKE $1
		)
	 ORDER BY performer, album, track
		;
	==SQLITE==
	sql-reply ''
}

$list || PipeEdit='| pipedit song.list'
[[ -t 1 ]]&& Pager='| less -FLSwX'

function main {
	for W; do
		W="%$W%"
		SQLify W
		show-$which "$W"
	done
}

eval "main \"\$@\" ${PipeEdit:-} ${Pager:-}"; exit

# Copyright (C) 2019 by Tom Davis <tom@greyshirt.net>.
