#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2022-10-12,22.18.38z/b19d62>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

MARGIN=4
nomail='\033[35mnone\033[39m'

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Do downloads simulateously.
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
		\:)	die USAGE "Option ^B-$OPTARG^b requires an argument.";			;;
		*)	bad-programmer "No getopts action defined for ^T-$Option^t.";	;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
function status-update { # {{{1
	print -r -- "${1:?}	${2:?}	${3:?}"
} # }}}1
function do-one-acct { # {{{1
	local T S A H a b c d e msg
	local -i10 new=0 got=0

	needs-file -or-warn ./${1:?} || return 1

	status-update "$2" "$MARGIN" "\033[1;36m$1\033[22;39m"
	fetchmail -f ./$1 --pidfile ./$1.pid |
		while IFS=' ()' read -r T a b S c d A e H; do
			if [[ $T == reading* ]]; then
				((got+=1))
				status-update "$2" "$INFOPOS" "$got/$new"
			elif [[ $A == $1 ]]; then
				new=$((T-S))
				if ((new)); then
					msg="0/$new"
				else
					msg=$nomail
				fi
				status-update "$2" "$INFOPOS" "$msg"
			elif [[ $T == 'fetchmail: No mail for'* ]]; then
				status-update "$2" "$INFOPOS" "$nomail"
			else
				status-update 20 1 "$T $a $b $S $c $d $A $e $H"
			fi
		done
	status-update "$2" "$MARGIN" "$1"
} # }}}1
function async-download { # {{{1
	typeset -i10 i=0
	for acct; do
		i=$((i+1))
		do-one-acct $acct $i &
	done
	wait
} # }}}1
function main { # {{{1
	async-download "$@" | while IFS='	' read -r ln col msg; do
		print -- "\033[$((top+ln));${col}H$msg"
	done
} # }}}1
function setup-screen { # {{{1
	local maxlen l acct

	eval "$(resize)"
	((LINES<$#))&& warn "Screen is too short, will be fudged."
#	tput clear

	maxlen=0
	for acct; do
		l=${#acct}
		((maxlen<l))&& maxlen=$l
	done
	INFOPOS=$((maxlen+(MARGIN*2)))
} # }}}1

needs needs-cd needs-file fetchmail i-can-haz-inet get-row-col

i-can-haz-inet || die "$REPLY"

needs-cd -or-die "$XDG_CONFIG_HOME/fetchmail/T"
(($#))|| {
	set -- *@*.*
	[[ $1 == *\* ]]&& die "No accounts to download."
  }

setup-screen "$@"
trap 'tput cnorm' EXIT
tput civis
h1 "Fetching remote mail"

top=$(get-row-col)
top=${top% *}

main "$@"; print -- "\033[$(($#+top+1));1H"; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
