#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2019-01-20:tw/20.01.57z/1765632>
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
	         Find an existing password.
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

(($#))|| die 'Expected one argument ^Uhostglob^u.'
(($#==1))||	die 'Too many arguments. Expected ^Uhostglob^u.'

secrets="${XDG_DATA_HOME:?}"/secrets
[[ -d $secrets ]]|| die 'No secrets directory.'
cd $secrets || die 'Could not ^Tcd^t to ^Bsecrets^b.'

set -- *"$1"*.pwd
[[ "$*" == \**\*.pwd ]]&& exit 1

choice="$(umenu "$@")"|| exit 1

print -- "${choice%.pwd}"

# Copyright (C) 2019 by Tom Davis <tom@greyshirt.net>.
