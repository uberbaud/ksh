#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2022-05-20,01.20.56z/82ea07>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

set -A return_addr -- 'Tom Davis' '10227 Kerns Rd' 'Huntersville, NC 28078'
NL='
'

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Wrapper around ^Tgen-envelope-ps.pl^t and ^Tlpr^t
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
function show_plerr_and_die { # {{{1
	local IFS="$NL"
	set -- $(print -r -- "$plerr" | sed -E -e 's/\(.*//')
	die "$spark_gen_ps fails to compile" "$@"
} # }}}1
function verify-gen_ps { # {{{1
	local REPLY
	sparkle-path "$gen_ps"
	spark_gen_ps=$REPLY

	[[ -a $gen_ps ]]|| die "$spark_gen_ps does not exist."
	[[ -f $gen_ps ]]|| die "$spark_gen_ps is not a file."
	[[ -x $gen_ps ]]|| die "$spark_gen_ps is not executable."
	plerr=$(perl -c "$gen_ps" 2>&1) || show_plerr_and_die
} # }}}1
function main { # {{{1
	local tmpFile

	sparkle <<-\
	===SPARKLE===
	^OTODO^o
	    Do database/file thingie for getting an address.
	===SPARKLE===

	NOT-IMPLEMENTED
	((${recipient_addr[*]:+1}))|| die 'No recipient address'

	set -- "${recipient_addr[@]}"
	((${recipient_addr[*]:+1}))&&
		set -- "$@" -r "${return_addr[@]}"

	tmpFile=$(mktemp) || die "Could not ^Tmktemp^t."
	trap "rm -f '$tmpFile'" EXIT

	$gen_ps "$@" >$tmpFile ||
		die "Failed to generate ^Benvelope postscript^b."

	$LPR -o raw -o InputSlot=ManualFeed "$tmpFile"
} # }}}1

LPR=/usr/local/bin/lpr
needs perl sed sparkle-path $LPR

gen_ps=$HOME/bin/perl/gen-envelope-ps.pl
verify-gen_ps

main "$@"; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
