#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-08-07:tw/18.20.40z/26a3999>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

: ${FPATH:?Run from within KSH}

fAccts=${XDG_CONFIG_HOME:?}/mail/fetchmail
Prefix='  '

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t ^[^T-a^t^] ^[^T-r^t^]
	         List accounts in ^Baccounts^b file
	           ^T-a^t  Lists all accounts, including ^Imanual-download-only^i.
	           ^T-r^t  Lists in ^Iraw^i form (suitable for machine processing).
	       ^T${PGM} -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
showAll=false
while getopts ':arh' Option; do
	case $Option in
		a)	showAll=true;											;;
		r)	Prefix='';												;;
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
					'warnOrDie is [1m${warnOrDie}[22m.'
	esac
} # }}}1
function list-accts { # {{{1
	for f in *; do 
		[[ -h $f ]]&& continue
		[[ -f $f ]]|| continue
		print -r -- "$Prefix$f"
	done
} # }}}1
function main { # {{{1
	list-accts
	$showAll && { needs-cd SKIP; list-accts; }
} # }}}1

(($#))&& die "Did not expect any arguments other than flags."
needs needs-cd
needs-cd -or-die "$fAccts"

main | sort; exit

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
