#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2020-12-01,23.32.43z/989ae4>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Mirror files or directories to another machine
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
function warnOrDie { #{{{1
	case $warnOrDie in
		die)  die "$@" 'Use [1m-f22m to force an edit.';		;;
		warn) warn "$@";											;;
		*)    die '[1mProgrammer error[22m:' \
					'warnOrDie is [1m${warnOrDie}[22m.';		;;
	esac
} # }}}1
function validate-exists {
	local failures=0
	for f; do
		[[ -a "$f" ]]&& continue
		desparkle "$f"
		warn "^B$REPLY^b does not exist"
		((failures++))
	done
	return $failures
}
needs new-array is-known-host desparkle
(($#<2))&& die 'Missing required arguments. Expected ^Ufile…^u ^Uhost^u'

# wrap script guts in a function so edits to this script file don't 
# affect running instances of the script.
function sendem {
	local fullpath
	for p; do
		fullpath="$(readlink -fn "$p")"
		scp -r "$fullpath" $AWAY:"$fullpath"
	done
}

new-array F
while (($#>1)) { +F "$1"; shift; }
validate-exists "${F[@]}" || die 'Cannot send nonexistent files' quitting

AWAY="$1"
is-known-host $AWAY || die "^B$AWAY^B is not a known host."

sendem "${F[@]}"; exit

# Copyright (C) 2020 by Tom Davis <tom@greyshirt.net>.
