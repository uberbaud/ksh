#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-08-07:tw/18.13.42z/3c5a944>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t ^[^Uacct list^u^]
	         Download (fetchmail), import into NMH (inc), and do some
	         processing.
	       ^T${PGM} -l^t
	         List available accounts.
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
function list-accts { # {{{2
	laccts=${XDG_CONFIG_HOME:?}/fetchmail/listAccts.ksh
	needs $laccts
	$laccts
} # }}}2
while getopts ':lh' Option; do
	case $Option in
		l)  list-accts; exit;										;;
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
function warnOrDie { #{{{1
	case $warnOrDie in
		die)  die "$@" 'Use [1m-f22m to force an edit.';		;;
		warn) warn "$@";											;;
		*)    die '[1mProgrammer error[22m:' \
					'warnOrDie is [1m${warnOrDie}[22m.';		;;
	esac
} # }}}1

i-can-haz-inet || die "$REPLY"

accToFetch=${XDG_CONFIG_HOME:?}/fetchmail/accTofetch.ksh
needs $accToFetch inc pick scan mark fetchmail

notify 'Generating ^Sfetchmailrc^s.'
(($#))|| set -- \*
$accToFetch "$@"

function P { printf '      ^F{4}─^f %s\n' "$1" | sparkle >&2; }

notify 'Downloading remote messages…'
fetchmail 2>&1 | while read -r resp; do
	case "$resp" in
		'reading message '*) continue; ;;
		*' message'*seen\)*)
			tM="${resp%% *}"
			sM="${resp#*\(}"; sM="${sM% seen\) *}"
			N=$((tM-sM))
			W="${resp#* for }"; W="${W% at *}"
			M=message; [[ $resp == *messages* ]]&& M=messages
			if ((N)); then
				P "Getting ^F{5}$N^f $M for ^F{5}$W^f."
			else
				P "No new messages for ^F{5}$W^f."
			fi
			;;
		*' message'*)
			N="${resp%% *}"
			W="${resp#* for }"; W="${W% at *}"
			M=message; [[ $resp == *messages* ]]&& M=messages
			if ((N)); then
				P "Getting ^S$N^s $M for ^S$W^s."
			else
				P "No new messages for ^S$W^s."
			fi
			;;
		'fetchmail: No mail for '*)
			W="${resp#* for }"; W="${W% at *}"
			P "No new messages for ^S$W^s."
			;;
		*) warn "$resp"; ;;
	esac
done

# regenerate fetchmail with all accounts enables
$accToFetch

msgCount=$(from|wc -l)
((msgCount))|| { notify "Nothing more to do, quitting."; return 0; }

/usr/bin/clear # clear, but keep the buffer
mark +inbox all -sequence oldhat 2>/dev/null
notify 'Incorporating new mail'
inc -nochangecur >/dev/null

new-array scanout
new-array groups

function group {
	mark +inbox -sequence x -delete all
	x="$(pick +inbox -sequence x -sequence "$@")"; x="${x:-0}"; x="${x% *}"
	mark +inbox -sequence x -delete oldhat
	y="$(pick +inbox x -nolist)"; y="${y:-0}"; y="${y% *}"
	(($y+$x))&& {
		+scanout "$1:" "new $y, total $x"
		+groups "$1"
		mark +inbox -sequence L -add "$1"
	  }
} 2>/dev/null

group drgfly    --list-id 'users\.dragonflybsd\.org'
group otech     --list-id 'tech\.openbsd\.org'
group obugs     --list-id 'bugs\.openbsd\.org'
group omisc     --list-id 'misc\.openbsd\.org'
group obsd      --list-id 'source-changes\.openbsd\.org'

scanseq='¬L'
[[ -n "$(flist +inbox -sequence L -noshowzero)" ]]|| scanseq='all'
scan +inbox $scanseq
: >"$NMH/groupmail" # truncate, we'll append if we have any groups
groups-not-empty && {
	printf '                      %-9s %s\n' "${scanout[@]}"
	print -r -- "${groups[*]}" >"$NMH/groupmail"
  }

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
