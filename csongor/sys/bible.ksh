#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2021-12-07,04.15.11z/d8f241>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^Ubook^u ^Uverse spec^u ^S[…]^s
	         Print bible verses. Where ^Uverse spec^u is
	           ^Uchapter^u^T-^t^Uchapter^u
	           ^Uchapter^u^[^T:^t^Uverse 1^u^]^[^T-^t^Uverse N^u^]
	           ^Uchapter^u^[^T:^t^Uverse 1^u^]^[^T-^t^Uchapter^u^T:^t^Uverse N^u^]
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
function show-book { # {{{1
	NOT-IMPLEMENTED
} # }}}1
function show-chapter { # {{{1
	NOT-IMPLEMENTED
} # }}}1
function show-chapters { # {{{1
	NOT-IMPLEMENTED
} # }}}1
function show-verse-of-chapter { # {{{1
	NOT-IMPLEMENTED
} # }}}1
function show-verses-of-chapter { # {{{1
	NOT-IMPLEMENTED
} # }}}1
function show-verses-of-chapters { # {{{1
	NOT-IMPLEMENTED
} # }}}1
function bad-spec { # {{{1
	local REPLY
	gsub : '^b^T:^t^B' "$3"
	gsub - '^b^T-^t^B' "$REPLY"
	warn "Starting $1 comes after ending $1 for ^B^U$2^u $REPLY^b."
} # }}}1
function main { # {{{1
	local booked Book cs ce c s e vs ve REPLY
	booked=false
	while (($#)); do
		[[ $1 == ?([123])+([A-Za-z ]) ]]&& {
			$booked && show-book "$Book"
			Book=$1; shift; booked=true; continue;
	  	}

		booked=false
		[[ -n ${Book:-} ]]|| {
			warn "Missing ^Ubook^u parameter for ^B$1^b."
			continue
		  }
		case $1 in
			+([0-9])?(:))
				show-chapter "$Book" ${1%:}
				;;
			+([0-9])-+([0-9]))
				cs=${1%-*}
				ce=${1#*-}
				if ((cs<=ce)); then
					show-chapters "$Book" $cs $ce
				else
					bad-spec chapter "$Book" "$1"
				fi
				;;
			+([0-9]):+([0-9]))
				show-verse-of-chapter "$Book" ${1%:*} ${1#*:}
				;;
			+([0-9]):+([0-9])-+([0-9]))
				c=${1%:*}
				s=${1#*:}; s=${s%-*}
				e=${1#*-}
				if ((s<=e)); then
					show-verses-of-chapter "$Book" $c $s $e
				else
					bad-spec verse "$Book" "$1"
				fi
				;;
			+([0-9]):+([0-9])-+([0-9]):+([0-9]))
				cs=${1%-*}
				vs=${cs#*:}
				cs=${cs%:*}
				ce=${1#*-}
				ve=${ce#*:}
				ce=${ce%:*}
				if ((cs<ce)); then
					show-verses-of-chapters "$Book" $cs $vs $ce $ve
				else
					bad-spec chapter "$Book" "$1"
				fi
				;;
			*)
				gsub : '^b^T:^t^B' "$1"
				gsub - '^b^T-^t^B' "$REPLY"
				die "Bad verse specification ^B^U$Book^u $REPLY^b."
				;;
		esac
		shift
	done
	$booked && show-book "$Book"
} # }}}1

(($#))|| die 'Missing required parameters.'


main "$@"; exit

# Copyright (C) 2021 by Tom Davis <tom@greyshirt.net>.
