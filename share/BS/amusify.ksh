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
	^F{4}Usage^f: ^T$PGM^t ^[^T-d^t^] ^Umusic_file^u ^S…^s
	         Hardlink ogg file (or convert in to) to amuse directory, and
	         update database with relevant information.
	           ^T-d^t  Turn on debug output and keep temporary files.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
debug=false
function bad_programmer {	# {{{2
	die 'Programmer error:'	\
		"  No getopts action defined for [1m-$1[22m."
  };	# }}}2
while getopts ':dh' Option; do
	case $Option in
		h)	usage;												;;
		d)	debug=true;											;;
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
	[[ -n $(mediainfo --Output='Audio;%Format%' "$MUSIC_FILE") ]]||
		die "^Does Bnot^b contain a known audio encoding:" "^N$MUSIC_FILE^n"
} # }}}1
function mk-mediainfo-output-template { # {{{1
	local ln comment suffix

	MEDIAINFO_FORMAT=$WORK_DIR/miFmt
	while IFS=\# read ln comment; do
		[[ -n $ln ]]|| continue
		[[ $ln == *\; ]]&& suffix= print || suffix='\n'
		print -rn -- "$ln${suffix:-}"
	done >$MEDIAINFO_FORMAT <<-===
		Audio;
		fmt/audio/%Format%
		file/hertz/%SamplingRate%
		file/channels/%Channels%
		file/bitdepth/%BitDepth%
		file/duration/%Duration%

		General;
		fmt/file/%Format%
		id/title/%Title%
		# id/description is everything in title enclosed in () or []
		bundle/genre/%Genre%
		bundle/compilation/%Collection%
		bundle/album/%Album/Sort%
		bundle/grouping/%Grouping%
		bundle/grouping/%Part%
		bundle/disks/%Part/%Part/Position_Total%
		bundle/disknumber/%Part/Position%
		bundle/tracks/%Track/Position_Total%
		bundle/tracknumber/%Track/Position%
		date/release/%Released_Date%
		date/encoded/%Encoded_Date%
		date/mastered/%Mastered_Date%
		date/recorded/%Recorded_Date%
		other/copyright/%Copyright%
		entity/label/%Label%
		entity/performer/%Performer%
		entity/composer/%Composer%
		entity/albumartist/%Album/Performer%
		entity/performer/%Accompaniment%
		entity/arranger/%Arranger%
		entity/lyricist/%Lyricist%
		entity/conductor/%Conductor%
	===

} # }}}1
function get-all-mediainfo { # {{{1
	local fFMT
	fFMT=file://$MEDIAINFO_FORMAT
	mediainfo --Inform="$fFMT" "$MUSIC_FILE" >$fINFO ||
		die "mediainfo"

	sed -i.raw -E -e '/^$/d' -e '/\/$/d' "$fINFO"
} # }}}
function convert-to-ogg-if-not-already-ogg { # {{{1
	egrep -q '^fmt/file/Ogg' "$fINFO" && return
	ffmpeg -i "$MUSIC_FILE" "$fOGG" >$fLOG 2>&1 || return
	[[ -f $fOGG ]]
} # }}}1
function get-hash-name-from-ogg { # {{{1
	ckSum=$(oggdec -QRo - "$fOGG" | cksum -a sha384b)
	fName=${ckSum#?}
	fPath=${ckSum%"$fName"}
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
	dUNZIP=$WORK_DIR/Z
	mkdir "$dUNZIP" || die "Could not ^Tmkdir ^B$dUNZIP^b."
	add-exit-actions "rm -rf '$dUNZIP'"

	unzip -jd"$dUNZIP" "${1:?}" || die 'do-safe-unzip'
} # }}}1
function do-one-file { # {{{1
	local MUSIC_FILE=$1
	(do-steps) && print true >$fSTEPS
} # }}}1
function do-one-item { # {{{1
	local fsobj f REPLY
	fsobj=$1
	[[ -f $fsobj && $fsobj == *.zip ]]&& {
		do-safe-unzip "$fsobj"
		fsobj=${dUNZIP:-}
	  }

	if [[ -f $fsobj ]]; then
		do-one-file "$fsobj"
	elif [[ -d $fsobj ]]; then
		for f in "$fsobj"/*; do
			[[ -f $f ]]&& do-one-file "$f"
		done
	else
		warn "^B$1^b is neither a ^Ifile^i nor a ^Idirectory^i."
	fi
} # }}}1
function CleanUp { # {{{1
	[[ -f $fSTEPS ]]&& mark-steps-complete
	if $debug || [[ -s $fERR ]]; then
		warn "^RKept ^B$WORK_DIR^b.^r"
		[[ -s $fERR ]]&& print '^RSee ^Berrors^b and ^BLOG^b.^r'
		return
	fi
:	rm -rf "$WORK_DIR";
} # }}}1

WORK_DIR=$(mktemp -dt @-XXXXXXXXX) || die "Could not ^Tmktemp -d^t."
$debug && notify "Created ^B$WORK_DIR^b"
fINFO="$WORK_DIR"/m.info
fWAV="$WORK_DIR"/m.ogg
fOGG="$WORK_DIR"/m.wav
fLOG="$WORK_DIR"/LOG
fERR="$WORK_DIR"/errors
fSTEPS="$WORK_DIR"/stpes

needs unzip mediainfo ffmpeg

mk-mediainfo-output-template

use-steps

+ bail-if-not-audio-file				die
+ get-all-mediainfo						warn
+ convert-to-ogg-if-not-already-ogg		warn
+ get-hash-name-from-ogg				warn
+ verify-ogg-isnt-already-amusified		false
+ add-info-to-db						warn
+ mv-ogg-to-amuse-repository			warn

for F {(do-one-item "$F")}; CleanUp; exit

# Copyright (C) 2020 by Tom Davis <tom@greyshirt.net>.
