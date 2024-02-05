#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2020-01-17,22.30.55z/32551f0>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

Q=6
F='^F{0}'
EDIT=${VISUAL:-${EDITOR:-vi}}
NL='
' # keep this quote to capture
TAB='	'

# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-d^t^|^T-D^t^] ^Umusic_file^u ^S…^s
	         Hardlink ogg file (or convert in to) to amuse directory, and
	         update database with relevant information.
	           ^T-d^t  Turn on debug output and keep temporary files.
	           ^T-D^t  ^T-d^t plus set ^O$^o^VSQL_VERBOSE^v to ^Ttrue^t.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
debug=false
while getopts ':dDh' Option; do
	case $Option in
		h)	usage;														;;
		d)	debug=true;													;;
		D)	debug=true; SQL_VERBOSE=true;								;;
		\?)	die "Invalid option: ^B-$OPTARG^b.";						;;
		\:)	die "Option ^B-$OPTARG^b requires an argument.";			;;
		*)	bad-programmer "Undefined getopts action: ^B$Option^b.";	;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
function bail-if-not-audio-file { # {{{1
	[[ -n $(mediainfo --Output='Audio;%Format%' "$MUSIC_FILE") ]]||
		die "^Does ^Bnot^b contain a known audio encoding:" "^N$MUSIC_FILE^n"
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
		file/endian/%Format_Settings_Endianness%
		file/sign/%Format_Settings_Sign%

		General;
		fmt/file/%Format%
		id/title/%Title%
		# id/description is everything in title enclosed in () or []
		bundle/genre/%Genre%
		bundle/compilation/%Collection%
		bundle/album/%Album/Sort%
		bundle/album/%Album%
		bundle/grouping/%Grouping%
		bundle/grouping/%Part%
		bundle/disks/%Part/Position_Total%
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
		entity/performer/%Original/Performer%
		entity/performer/%Accompaniment%
		entity/composer/%Composer%
		entity/albumartist/%Album/Performer%
		entity/arranger/%Arranger%
		entity/lyricist/%Lyricist%
		entity/lyricist/%Original/Lyricist%
		entity/conductor/%Conductor%
	===

} # }}}1
function get-all-mediainfo { # {{{1
	local fFMT
	fFMT=file://$MEDIAINFO_FORMAT
	mediainfo --Inform="$fFMT" "$MUSIC_FILE" >$fINF ||
		die "mediainfo"

	sed -i.raw -E -e '/^$/d' -e '/\/$/d' "$fINF"
} # }}}
function convert-to-ogg-if-not-already-ogg { # {{{1
	MUSIC_FILE_IS_OGG=true
	egrep -q '^fmt/file/Ogg' "$fINF" && return

	MUSIC_FILE_IS_OGG=false
	new-array opts
	+opts -i "$MUSIC_FILE"	# input file
	+opts -vn				# don't include video
	+opts -c:a libvorbis	# codec:audio
	+opts -qscale:a $Q		# quality
	+opts "$fOGG"			# ogg file name

	[[ -f $fOGG ]]&& rm -f "$fOGG"
	ffmpeg "${opts[@]}" >$fLOG 2>&1 || return
	[[ -f $fOGG ]]
} # }}}1
function get-hash-name-from-ogg { # {{{1
	local fName fPath
	ckSum=$(oggdec -QRo - "$fOGG" | cksum -a sha384b | tr / =)
	fName=${ckSum#?}
	fPath=${ckSum%"$fName"}
	AMUSIFIED_FILE=${AMUSE_DATA_HOME:?}/$fPath/$fName
} # }}}1
function verify-ogg-isnt-already-amusified { # {{{1
	! [[ -f $AMUSIFIED_FILE ]]&& return
	die "$MUSIC_FILE was previously ^Iamusified^i."
} # }}}1
function add-file-info-to-db { # {{{1
	local hz ch bits enc dur kind label value duration dtenths min
	typeset -l -L1 sign end

	#===================================================== GET FILE VALUES ===#
	while IFS=/ read -r kind label value; do
		[[ $kind == file ]]|| continue
		case $label in
			hertz)		hz=$value;									;;
			channels)	ch=$value;									;;
			bitdepth)	bits=$value;								;;
			duration)	dur=$value;									;;
			endian)		end=$value;									;;
			sign)		sign=$value;								;;
			*) bad-programmer "Unhandled ^Vlabel^v: ^B$label^b.";	;;
		esac
	done <$fINF
	[[ -n ${sign:-} && -n ${bits:-} && -n ${end:-} ]]&&
		enc=$sign$bits$end'e'

	local dtenths secs min frac S
	dtenths=${dur%??}
	secs=${dur%???}
	frac=${dur#$secs}
	min=$((secs/60))
	typeset -Z2 S=$((secs%60))
	duration=$min'm:'$S.$frac

	#====================================================== INSERT INTO DB ===#
	SQLify ckSum duration
	enc=${enc:-\'\'}
	hz=${hz:-NULL}; ch=${ch:-NULL}; dtenths=${dtenths:-NULL}
	$debug && sparkle <<-===SPARKLE===
		$F^K{94}=== FILE INFO ====================^k
		  pcm_sha384b: ^B$ckSum^b
		  hertz:       ^B$hz^b
		  channels:    ^B$ch^b
		  encoding:    ^B$enc^b
		  duration:    ^B$duration^b
		  dtenths:     ^B$dtenths^b^f
	===SPARKLE===

	SQL <<-===SQL===
		INSERT OR IGNORE INTO amuse.files
				(pcm_sha384b, hertz, channels, encoding, duration, dtenths)
		VALUES	( $ckSum    ,$hz   ,$ch      ,$enc     ,$duration,$dtenths)
			 ;
	===SQL===

} # }}}1
function add-vtag { # {{{1
	local fid kind label value
	[[ -z "${4:-}" ]]&& return
	: ${1:?} ${2:?} ${3:?}
	fid=$1
	kind=$2
	label=$3
	value=${4##+([[:space:]])}; value=${value%%+([[:space:]])}
	[[ -z $value ]]&& return
	SQLify kind label value
	$debug &&
		notify "^G└^g $F^K{94}VTAGS^k $fid^f^, $F$kind^f^, $F$label^f^, $F$value^f"
	SQL <<-===SQL===
	INSERT OR IGNORE INTO amuse.vtags
				(file, kind, label, value)
		VALUES  ($fid,$kind,$label,$value)
		;
	===SQL===
} # }}}1
function write-title-file { # {{{1
	cat <<-===
		# Comments begin with '#', and along with empty lines are 
		# discarded. Non-empty, non-commented lines:
		#   line 1: title
		#   line 2: extended title description
		#   line n: ERROR
		# ORIGINALLY: ${1:?}
		${2:?}
	===
} # }}}1
function remove-Live-from-title-to-descr { # {{{1
	local prefix suffix
	prefix=${TITLE%%+( )\(Live?( Version)\)*}
	suffix=${TITLE##*\(Live?( Version)\)+( )}
	TITLE=$prefix\ $suffix
	SONG_IS_LIVE=Live
} # }}}1
function remove-Explicit-from-title-to-descr { # {{{1
	local prefix suffix
	prefix=${TITLE%%+( )\[Explicit\]*}
	suffix=${TITLE##*\[Explicit\]+( )}
	TITLE=$prefix\ $suffix
	SONG_IS_EXPLICIT=Explicit
} # }}}
function clean-title { # {{{1
	local fTitle IFS=$IFS T
	TITLE=${1:?}
	DESCR=''
	[[ $TITLE == +([A-Za-z0-9.,!?& \'\"-]) ]] && return

	[[ $TITLE == *\(Live?( Version)\)* ]]&& remove-Live-from-title-to-descr
	[[ $TITLE == *\[Explicit\]* ]]&& remove-Explicit-from-title-to-descr

	fTitle=$WORK_DIR/m.title
	write-title-file "$1" "$TITLE" >$fTitle
	typeset -i i
	while :; do
		$EDIT <$TTY >$TTY "$fTitle"
		sed -i~ -E -e 's/#.*$//' -e '/^[[:space:]]*$/d' "$fTitle"
		i=$(wc -l <$fTitle)
		((i==1||i==2))&& break
		warn 'Edited title must occupy 1.'
		yes-or-no Re-edit <$TTY || {
			warn "Title file was mis-edited."
			return
		  }
		T=$(<$fTitle)
		write-title-file "$1" "$T" >$fTitle
	===
	done
	IFS=$NL
	set -- $(<$fTitle)
	TITLE=${1:-}
	DESCR=${2:-}
} # }}}1
function clean-album { # {{{1
	ALBUM="${1%%*( )[]\(]*}"
} # }}}1
function add-vtags-to-db { # {{{1
	local fid dscr kind label value DESCR

	SQL "SELECT id FROM amuse.files WHERE pcm_sha384b = $ckSum;"
	fid=${sqlreply[0]}
	[[ $fid == +([0-9]) ]]|| {
		warn "Unexpected SQL amuse.files.id result" "${sqlreply[@]}"
		return
	  }

	# INSERT INTO vtags
	dscr=description
	expl=explicit
	DESCR=''
	SONG_IS_LIVE=''
	SONG_IS_EXPLICIT=''
	while IFS=/ read -r kind label value; do
		$debug && notify "^G┌──────^g $F$kind^f^/$F$label^f^/$F$value^f"
		[[ $kind == @(file|fmt) ]]&& continue
		case $label in
			title)
				clean-title "$value"
				add-vtag $fid $kind $label "$TITLE"				|| return
				add-vtag $fid $kind $dscr  "$DESCR"				|| return
				add-vtag $fid $kind live   "$SONG_IS_LIVE"		|| return
				add-vtag $fid $kind $expl  "$SONG_IS_EXPLICIT"	|| return
				;;
			album)
				clean-album "$value"
				add-vtag $fid $kind $label "$ALBUM" || return
				;;
			*)	add-vtag $fid $kind $label "$value" || return
				;;
		esac
	done <$fINF
} # }}}1
function add-info-to-db { # {{{1
	local rc
	SQL_AUTODIE=warn
	SQL 'BEGIN TRANSACTION'
	if add-file-info-to-db && add-vtags-to-db; then
		rc=0
		SQL 'COMMIT TRANSACTION'
	else
		rc=1
		SQL 'ROLLBACK TRANSACTION'
	fi
	return $rc
} # }}}1
function mv-ogg-to-amuse-repository { # {{{1
	# Hardlink (if originally ogg) OR mv (if converted) to
	if $MUSIC_FILE_IS_OGG; then
		ln -f "$MUSIC_FILE" "$AMUSIFIED_FILE" ||
			cp -f "$MUSIC_FILE" "$AMUSIFIED_FILE"
	else
		mv -f "$fOGG" "$AMUSIFIED_FILE"
	fi
} # }}}1
function do-safe-unzip { # {{{1
	dUNZIP=$WORK_DIR/Z
	mkdir "$dUNZIP" || die "Could not ^Tmkdir ^B$dUNZIP^b."
	add-exit-actions "rm -rf '$dUNZIP'"

	unzip -jd"$dUNZIP" "${1:?}" || die 'do-safe-unzip'
} # }}}1
function do-one-file { # {{{1
	local MUSIC_FILE=$1
	h3 "$MUSIC_FILE"
	(do-steps)
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
	if $debug || [[ -s $fERR ]]; then
		warn "^RKept ^B$WORK_DIR^b.^r"
		[[ -s $fERR ]]&& print '^RSee ^Berrors^b and ^BLOG^b.^r'
		return
	fi
	rm -rf "$WORK_DIR";
} # }}}1

WORK_DIR=$(mktemp -dt @-XXXXXXXXX) || die "Could not ^Tmktemp -d^t."
$debug && notify "Created ^B$WORK_DIR^b"

fINF="$WORK_DIR"/m.info
fOGG="$WORK_DIR"/m.ogg
fLOG="$WORK_DIR"/LOG
fERR="$WORK_DIR"/errors
TTY=${TTY:-$(tty)} || TTY=/dev/tty

needs SQL SQLify						\
	amuse:env bad-programmer			\
	cksum ffmpeg mediainfo needs-file oggdec tr unzip new-array

amuse:env || die "^Tamuse:env^t: $REPLY"
DB=$AMUSE_DATA_HOME/amuse.db3
needs-file -or-die "$DB"
SQLify DB
SQL "ATTACH $DB AS amuse;"

mk-mediainfo-output-template
use-steps

+ bail-if-not-audio-file				die
+ get-all-mediainfo						die
+ convert-to-ogg-if-not-already-ogg		die
+ get-hash-name-from-ogg				die
+ verify-ogg-isnt-already-amusified		false
+ add-info-to-db						die
+ mv-ogg-to-amuse-repository			die

mark-steps-complete

for FSOBJ {(do-one-item "$FSOBJ")}; CleanUp; exit

# Copyright (C) 2020 by Tom Davis <tom@greyshirt.net>.
