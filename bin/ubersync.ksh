#!/bin/ksh
# @(#)[:TpT~W!fOPp~o^JMNTd&8: 2017-08-08 19:26:18 Z tw@csongor]
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -A RHOSTS -- uberbaud.net yt.lan


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
	    ^GNote^g
	       Exporting ^S\$LOGLEVEL^s will set ^Tsynrdir^t to that log level.
	       Use ^Tsynrdir -h^t for allowable values.
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

KB=$KDOTDIR/bin/
docstore=$HOME/hold/DOCSTORE
[[ -a $docstore ]]|| die "^B$docstore^b does not exist."
[[ -d $docstore ]]|| die "^B$docstore^b is not a directory."
cd "$docstore" || die "Could not ^Tcd^t to ^B$docstore^b."

synropt="${LOGLEVEL:+"-L $LOGLEVEL"}"

function main {
	notify "Updating ^SDOCSTORE^s"
	$KB/savetracks.ksh

	for H in "${RHOSTS[@]}"; do
		notify "Syncing with ^B$H^b."
		$KB/synrdir.ksh $synropt $H:"$PWD" "$PWD"
	done
}

main "$@"; exit

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
