#!/bin/ksh
# <@(#)tag:tw.csongor.uberbaud.foo,2024-01-23,18.49.07z/34fff3a>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

Q=6

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-q^t ^UQ^u^] ^Uaudio in^u ^Uogg^u
	         Convert ^Uaudio in^u file (eg mp3, youtube webm, wav) to ^Uogg^u.
	           ^T-q^t ^UQ^u    Set quality, default is ^V$Q^v. Values may be between -1 and 10 and
	                   may include fractional parts in decimal. ^T6^t is approximately
	                   192 kbps which keeps loss under perception.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
while getopts ':q:h' Option; do
	case $Option in
		q)	Q=$OPTARG;														;;
		h)	usage;															;;
		\?)	die USAGE "Invalid option: ^B-$OPTARG^b.";						;;
		\:)	die USAGE "Option ^B-$OPTARG^b requires an argument.";			;;
		*)	bad-programmer "No getopts action defined for ^T-$Option^t.";	;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
function main { # {{{1
	local fAudio ogg
	fAudio=$1
	ogg=$2
	ffmpeg -i "$fAudio" -vn -c:a libvorbis -qscale:a $Q "${ogg%.ogg}".ogg
} #}}}1

needs ffmpeg needs-file realpath

(($#))|| die 'Missing required parameters ^Uaudio in^u and ^Uogg^u.'
fAudio=$(realpath "${1:?}") || die "No such file ^B$1^b."
needs-file -or-die "$fAudio"
shift
(($#))|| die 'Missing required parameter ^Uogg^u.'

[[ $Q == @(-1?(.*(0))|-0.*([0-9])|[0-9]?(.*([0-9]))|10?(.*(0))) ]]||
	die 'Quality ^Bmust^b be a real number between ^T-1^t and ^T10^t.'

main "$fAudio" "$@"; exit

# Copyright (C) 2024 by Tom Davis <tom@greyshirt.net>.
