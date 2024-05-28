#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-08-07:tw/18.13.42z/3c5a944>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t ^[^T-n^t^] ^[^Uacct_list^u^]
	         Download (fetchmail), import into MMH (inc), and do some
	         processing.
	           ^T-n^t  Don't download anything, just do the other bits.
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
DOWNLOAD=true
while getopts ':nh' Option; do
	case $Option in
		n)	DOWNLOAD=false;											;;
		h)	usage;													;;
		\?)	die "Invalid option: [1m-$OPTARG[22m.";				;;
		\:)	die "Option [1m-$OPTARG[22m requires an argument.";	;;
		*)	bad_programmer "$Option";								;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
function group { # {{{1
	mark +inbox -sequence x -delete a
	x=$(pick +inbox -sequence x -sequence "$@"); x=${x:-0}; x=${x% *}
	mark +inbox -sequence x -delete oldhat
	y=$(pick +inbox x -nolist); y=${y:-0}; y=${y% *}
	((y+x))&& {
		+scanout "$1:" "new $y, total $x"
		+groups "$1"
		mark +inbox -sequence L -add "$1"
	  }
} 2>/dev/null # }}}1
function P { printf '      ^F{4}─^f %s\n' "$1" | sparkle >&2; }

needs m-list-new m-msgcount mark pick
if $DOWNLOAD; then
	needs use-app-paths
	use-app-paths mail
	needs inc get-remote-mail.ksh

	tput clear

	msgCount=$(m-msgcount)
	((msgCount))&& {
		notify "^K{136} Putting ^B$msgCount^b old messages in ^Isequence^i ^Boldhat^b. ^k"
		mark +inbox a -sequence oldhat 2>/dev/null
	  }

	msgCount=$(from|wc -l)
	((msgCount))&& {
			notify 'Incorporating ^Slocal^s messages.'
			inc -nochangecur >/dev/null
		}

	get-remote-mail.ksh "$@"
fi

msgCount=$(m-msgcount)
((msgCount))|| { notify 'Nothing to do' 'quitting'; exit 0; }

new-array scanout
new-array groups

group obsd      --list-id 'source-changes\.openbsd\.org'
group omisc     --list-id 'misc\.openbsd\.org'
group otech     --list-id 'tech\.openbsd\.org'
group obugs     --list-id 'bugs\.openbsd\.org'
group drgfly    --list-id 'dragonfly'
group got       --list-id 'gameoftrees\.openbsd\.org'
group qutebrw   --list-id 'qutebrowser\.lists\.qutebrowser\.org'
group zig       --list-id '/ziglang\.lists\.sr\.ht'

m-list-new

GROUPMAIL=${MMH:?}/groupmail
[[ -e $GROUPMAIL ]]&& { [[ -w $GROUPMAIL ]]|| chmod u+w "$GROUPMAIL"; }
: >$GROUPMAIL # truncate, we'll append if we have any groups
groups-not-empty && {
	printf '                      %-9s %s\n' "${scanout[@]}"
	print -r -- "${groups[*]}" >"$MMH/groupmail"
  }

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
