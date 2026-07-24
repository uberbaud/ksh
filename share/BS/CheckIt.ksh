#!/bin/ksh
# <@(#)tag:tw.lukas.uberbaud.foo,2026-01-21,05.47.55z/24eac5c>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: "${FPATH:?Run from within KSH}"

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm" PGM
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^Ufsobj^u ^S…^s
	        Moves files and directories into ^O~^o^/^TCheckIt^t
	        then creates a replacement softlink.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
while getopts ':h' Option; do
	case $Option in
		h)	usage;															;;
		\?)	die USAGE "Invalid option: ^B-$OPTARG^b.";						;;
		:)	die USAGE "Option ^B-$OPTARG^b requires an argument.";			;;
		*)	bad-programmer "No getopts action defined for ^T-$Option^t.";	;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
function move-and-link { # {{{1
	local file dir
	mv "$file" "$dir/"			|| return
	ln -s "$dir/$file" "$file"	&& return
	warn "Could not create a soft link from ^T$dir/$file^t to ^T$file^t."
} # }}}1
function main { # {{{1
	for fo; do
		sparkle-path "$fo"
		dFO=$REPLY
		if [[ -f $fo || -d $fo ]]; then
			move-and-link "$fo" "$CI" ||
				warn "Could not ^TCheckIt^t $dFO"
		else
			warn "$dFO is neither ^Bfile^b nor ^Bdir^b."
		fi
	done
} #}}}1

needs needs-path sparkle-path

CI=${HOME:?}/CheckIt
needs-path -or-die "$CI"
main "$@"; exit

# Copyright (C) 2026 by Tom Davis <tom@greyshirt.net>.
