#!/bin/ksh
# @(#)[:yr4icdoH>bPrsUEV&7B-: 2017-11-22 04:40:03 Z tw@csongor]
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-dfpsS^t^] ^[^Ufile^u^]
	         List swaps for a given file, or all files, one line per swap.
	         Show, with a space delimiting, the
	           ^T-d^t  ^Bdirectory^b,
	           ^T-f^t  ^Bfile^b being edited.
	           ^T-p^t  ^Bpid^b of any still running session,
	           ^T-s^t  ^Bname^b of the ^Bswap file^b,
	           ^T-S^t  full ^Bpathname^b of the ^Bswap file^b,
	         If no flags are given it's as if ^T-Sp^t were.
	         This is just a reformating of the ^Tnvim -r^t command.
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
set -A show --
function show+ { local i; for i { show[${#show[*]}]="$i"; } }
while getopts ':dfpsSh' Option; do
	case $Option in
		d)	show+ '$DIR';											;;
		f)	show+ '$FILE';											;;
		p)	show+ '$PID';											;;
		s)	show+ '$SWPF';											;;
		S)	show+ '$DIR/$SWPF';										;;
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
function show-prev { #{{{1
	if [[ -z $FILE ]]; then
		return 0
	elif $showAll; then
		eval "print -- ${show[*]}"
	elif [[ $FILE == $file ]]; then
		eval "print -- ${show[*]}"
	fi

	SWPV=''; FILE=''; PID='-'
	return 0
} #}}}1

(($#>1))&&	die 'Unexpected parameters. Expected ^Uflags^u and ^Ufilename^u.'
((${#show[*]}))|| set -A show -- '"$DIR/$SWPF"' '"$PID"'
needs nvim

showAll=true; file=''
(($#))&& {
	showAll=false
	[[ -a $1 ]]|| die "^B$1^b does not exist."
	[[ -f $1 ]]|| die "^B$1^b is not a file."
	file="$(readlink -fn "$1")"
	[[ -n $file ]]|| die 'Total weirdness, ^Treadlink^t fails.'
  }

PID='-'
splitstr NL "$(nvim -r 2>&1|tr -d '\r')" swapinfo
for ln in "${swapinfo[@]}"; do
	[[ $ln == '   In directory '*: ]]&& {
		show-prev
		ln="${ln#   In directory }"
		ln="${ln%%*(/):}"
		DIR="$ln"
		continue
	  }
	[[ $ln == [1-9]*([0-9]).* ]]&& {
		show-prev
		ln="${ln##+([0-9]).+( )}"
		SWPF="$ln"
		continue
	  }
	[[ $ln == +( )'file name: '* ]]&& {
		ln="${ln#+( )file name: }"
		eval FILE="$ln"
		continue
	  }
	[[ $ln == +( )'process ID: '+([0-9])' (still running)' ]]&& {
		ln="${ln#+( )process ID: }"
		ln="${ln% \(still running\)}"
		PID="$ln"
		continue
	  }
done
show-prev

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
