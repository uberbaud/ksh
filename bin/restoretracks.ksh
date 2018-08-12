#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2018-08-12:tw/04.01.02z/7e56f>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Recreate a file in its place from a DOCSTORE file.
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
function warnOrDie { #{{{1
	case $warnOrDie in
		die)  die "$@" 'Use [1m-f22m to force an edit.';		;;
		warn) warn "$@";											;;
		*)    die '[1mProgrammer error[22m:' \
					'warnOrDie is [1m${warnOrDie}[22m.';		;;
	esac
} # }}}1

DOCSTORE="$HOME/hold/DOCSTORE"
[[ -d $DOCSTORE ]]|| die 'No ^B~/hold/DOCSTORE^b directory.'
builtin cd "$DOCSTORE" || die 'Could not ^Tcd^t to ^BDOCSTORE^b'

function do-one {
	local fnpre="$1"
	set -- $fnpre*
	[[ $1 == $fnpre\* ]]&& {
		warn "No matching file ^BDOCSTORE/$1^b*"
		return 1
	  }
	(($#>1))&& {
		warn "Ambiguous prefix ^B$fnpre^b."
		return 1
	  }
	zcat "$1" |&
	read -rp restname
	restdir="${restname%/*}"
	[[ -d $restdir ]]|| mkdir -p "$restdir" || {
		warn "Could not create directory ^B$restdir^b."
		return 1
	  }
	cat <p >"$restname"
}

for f; do do-one "$f"; done; exit

# Copyright (C) 2018 by Tom Davis <tom@greyshirt.net>.
