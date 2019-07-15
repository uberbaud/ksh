#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2019-07-15,15.48.36z/574c245>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-R^t^] ^Ustruct_name^u ^[^Tdir1^t … ^TdirN^t^]
	         Finds a C struct definition in *.h found in given directories, or ^S.^s.
	           ^T-R^t  recurseses subdirectories.
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
recurse=false
while getopts ':hR' Option; do
	case $Option in
		R)	recurse=true;										;;
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

needs find awk

(($#))|| die 'Missing required parameter ^Sstruct_name^s'
sname="$1"; shift
(($#))|| set -- .

$recurse || depth='-maxdepth 1'
set -- $(find "$@" -type f -name '*.h' ${depth:-})

(($#))|| die 'No header files found.'

awkpgm="$(cat)" <<-\
	==AWK==
	BEGIN { p=0; f=0 }
	/struct[ \t]+$sname[ \t]*{/ {
			printf("%s:%d\n", FILENAME, FNR);
			p=1
			f=1
		}
	p	{ printf( "    %s\n", \$0 ) }
	/}/ { p=0 }
	END { exit !f }
	==AWK==

awk "$awkpgm" "$@"


# Copyright (C) 2019 by Tom Davis <tom@greyshirt.net>.
