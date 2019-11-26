#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2019-11-26,04.22.19z/1848e62>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

player='/home/tw/work/clients/me/util/amuse/prac/obj/sio-ogg-player'

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm" ^Usong id^u
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Play one song. One (1) song only.
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

(($#))|| die 'Expected one (1) ^Usong id^u.'
[[ $1 == +([0-9]) ]]|| die 'Expected ^Usong id^u (^Sinteger^s).'

needs amuse:get-workpath $player

amuse:get-workpath
cd "$REPLY" || die 'Could not ^Tcd^t to ^Samuse^s directory.'
SQL "ATTACH 'amuse.db3' AS amuse;"

SQL <<-==SQLITE==
	SELECT pcm_sha384b FROM files WHERE id = $1;
	==SQLITE==
F="${sqlreply[0]#?}"
P="${sqlreply[0]%"$F"}"
song="./$P/$F.oga"

#notify "  with: $player" "    in: $PWD" "trying: $song"
exec $player "$song"

# Copyright (C) 2019 by Tom Davis <tom@greyshirt.net>.
