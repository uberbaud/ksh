#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2019-12-03,21.31.29z/287b41f>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

eBG='48;5;31'
ePlayed="\\033[0;$eBG;38;5;249m"
ePlaying='\033[0;48;5;229;30m'
eNext="\\033[0;$eBG;30m"
eStatus='\033[0;1;38;5;226;48;5;246m'
TAB='	'
CONTINUE=true

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         test amuse style screen stuff
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
function get-size { #{{{1
	LINES=$(tput lines)
	COLUMNS=$(tput columns)
	PLAYED=$(((LINES-2)/4))
	PLAYING=$((PLAYED+1))
} #}}}1
function update-screen { # {{{1
	local i
	i=$PLAYED
	while ((i)); do
		((i--))
		IFS="$TAB" read -r id song || song=''
		BUFFER[i]="$song"
	done <played.lst
	IFS="$TAB" read -r id song <playing
	BUFFER[PLAYING-1]="$song"
	i=$((PLAYING-1))
	while ((++i<LINES)); do
		IFS="$TAB" read -r id song || song=''
		BUFFER[i]="$song"
	done <song.lst

	typeset -L$((COLUMNS-2)) L
	typeset status
	print -n -- "$ePlayed"
	i=0
	while ((i<$PLAYED)); do
		L="${BUFFER[i]:-~}"
		((i++))
		print -n -- "\033[$i;1H $L "
	done
	L="${BUFFER[i]:-~}"
	((i++))
	print -n -- "\033[$i;1H $ePlaying$L$eNext "
	while ((i<$LINES)); do
		L="${BUFFER[i]:-~}"
		((i++))
		print -n -- "\033[$i;1H $L "
	done
	print -n -- "$eStatus"
	status="    "
	if [[ -s final ]]; then
		status="$status final "
	else
		status="$status       "
	fi
	if [[ -s paused-at ]]; then
		status="$status paused "
	else
		status="$status        "
	fi
	[[ -s again ]]&&
		status="$status again: $(<again) "
	L="$status"
	print -n -- "\033[$i;1H $L \033[0m"
} # }}}1
function main-loop { #{{{1
	get-size
	set-alternate-screen
	while $CONTINUE; do
		update-screen
		jobs -p %sleep >/dev/null 2>&1 || { sleep 999 & }
		wait %sleep
	done
	kill -TERM %sleep  >/dev/null 2>&1
} #}}}1
function CleanUp { unset-alternate-screen; : >ui-pid;	}
function hTerm	{ CONTINUE=false;						}
function hWinch	{ get-size;								}
function hUsr	{ :;									}

needs amuse:env

trap hTerm	INT HUP TERM QUIT
trap hWinch WINCH
trap hUsr	USR1 USR2
add-exit-action CleanUp

amuse:env
cd "${AMUSE_RUN_DIR:?}" || die 'Could not ^Tcd^t to ^S$AMUSE_RUN_DIR^s.'

>ui-pid print -- $$

main-loop; exit

# Copyright (C) 2019 by Tom Davis <tom@greyshirt.net>.
