#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2019-03-17:tw/05.25.29z/2877f57>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[-n^]
	         Check for needed modules in ^S~/bin/perl^s and install with ^Tcpanm^t
	           ^T-n^t  Do not install
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
DRYRUN=false
while getopts ':nh' Option; do
	case $Option in
		n)	DRYRUN=true;										;;
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

needs new-array cpanm

cd ~/bin/perl || die 'Could not ^Tcd^t to ^S~/bin/perl^s.'
new-array wants

# wrap script guts in a function so edits to this script file don't 
# affect running instances of the script.
function main {
	set -- $(awk -F'[ \t;]' '/^[ \t]*use[ \t]/ {print $2}' *.pl|sort|uniq)
	for M { perl -M$M -e 1 || +wants "$M"; } 2>/dev/null
	wants-is-empty && {
		notify 'Everything ^Bused^b is installed.'
		return 0
	  }
	$DRYRUN && {
		warn '^NMissing wanted modules:^n' "${wants[@]}"
		return 0
	  }

	notify "Missing ^B${#wants[*]}^b wanted modules." "Installing with ^Tcpanm^t."
	cpanm "${wants[@]}"
}

main "$@"; exit

# Copyright (C) 2019 by Tom Davis <tom@greyshirt.net>.
