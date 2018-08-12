#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-08-08:tw/19.26.18z/1101710>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}
: ${KDOTDIR:?}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t
	         Update hold/DOCSTORE and sync with uberbaud.net.
	       ^T${PGM} -h^t
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
		h)	usage;													;;
		\?)	die "Invalid option: [1m-$OPTARG[22m.";				;;
		\:)	die "Option [1m-$OPTARG[22m requires an argument.";	;;
		*)	bad_programmer "$Option";								;;
	esac
done
# remove already processed arguments
shift $(($OPTIND - 1))
# ready to process non '-' prefixed arguments
# /options }}}1

docstore=$HOME/hold/DOCSTORE
tracking=$docstore/TRACK
[[ -d $tracking ]]|| die 'Could not find ^Btracking^b directory.'
cd $tracking || die 'Could not ^Bcd^b to ^Btracking^b directory.'

FS=''
GS=''

for t in *; do
	[[ -h $t ]]&& continue
	[[ -f $t ]]|| continue
	[[ -s $t ]]&& continue
	gsub '\\'  "$FS" "$t"
	gsub '\%'  "$GS" "$REPLY"
	gsub '%'   '/'   "$REPLY"
	gsub "$GS" '%'   "$REPLY"
	gsub "$FS" '\'   "$REPLY"
	[[ -f $REPLY ]]|| {
		warn "^B$t^b has moved." 'Erasing tracking info.'
		rm "$t"
		continue
	  }
	original="$REPLY"
	SHA384="$(cksum -qa sha384b "$original")"
	gsub '/' '_' "$SHA384"
	SHA384="$REPLY"
	FNAME=../$SHA384
	if [[ -f $FNAME ]]; then
		warn "sha384b already exists for ^B$t^b."
	else
		{
			print -- "$original"
			cat "$original"
		  } | gzip -qfno "$FNAME"
		chflags uchg "$FNAME"
	fi
	print -- "$SHA384" >"$t"
done

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
