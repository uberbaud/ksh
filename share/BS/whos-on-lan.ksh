#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2022-04-06,21.55.16z/562d4f6>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

NL='
'
# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^Ulan^u^]
	         ^Tping^t everything on ^Ulan^u, then ^Tarp -a^t
	         ^GNote: assumes mask of 255.255.255.0^g
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
function get-lan { # {{{1
	local IFS=$NL
	set -- $(ifconfig -a|awk '/^\tinet 192\.168/ {$1=$2;NF=1;print}')
	(($#))|| die 'Could not find a ^B192.168^b local area network.'
	(($#==1))||	die 'Too many LANs found:' "$@" 'Use ^Ulan^u option'
	print -r -- "$1"
} # }}}
function normalize-lan { # {{{1
	local IFS=.
	set -- ${1:?Missing required argument to normalize-lan.}
	(( $#==3 || $# == 4 ))|| return 1
	[[ $1 == +([0-9]) ]]|| return 1
	[[ $2 == +([0-9]) ]]|| return 1
	[[ $3 == +([0-9]) ]]|| return 1
	(($1>=0 && $1<=255))|| return 1
	(($2>=0 && $1<=255))|| return 1
	(($3>=0 && $1<=255))|| return 1

	print -r -- "$1.$2.$3"
} # }}}1
function ping-no-wait { # {{{1
	(ping -w 1 -c 1 -q "$1" >/dev/null 2>&1 &)
} # }}}1

function main {
	local lan i
	# get the network to check
	lan=$(normalize-lan ${1:-"$(get-lan)"}) ||
		die "^B$1^b is not a valid network address."

	# ping every address EXCEPT $lan.0 and $lan.255 which are reserverd
	i=1
	while ((i<255)); do
		ping-no-wait $lan.$i
		((i++))
	done
	wait
	arp -a|egrep -v '\(incomplete\)'
}

(($#>1))&& die 'Too many arguments. Expected zero or one (0-1).'
main "$@"; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
