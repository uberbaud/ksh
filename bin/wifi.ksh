#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2020-02-17,00.40.22z/5324581>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}
WIFI_DIR=${XDG_CONFIG_HOME:?}/wifi
WIFI_DEFAULT="$WIFI_DIR/default-join"

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Toggle wifi (iwm0 and em0 up/down) and connect to fred if available.
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

unalias doas
needs doas ifconfig
# wrap script guts in a function so edits to this script file don't 
# affect running instances of the script.
function main {
	em0status="$(ifconfig em0|awk -F': ' '/status/ {print $2}')"
	if [[ $em0status == 'no carrier' ]]; then
		doas ifconfig em0 down
		doas ifconfig iwm0 up
		doas ifconfig iwm0 join "$@"
	else
		doas ifconfig iwm0 -join "$1"
		doas ifconfig iwm0 down
		doas ifconfig em0 up
	fi
}

doas true||doas true||doas true|| die "Bad credentials"
#   v capture a newline in a variable
IFS='
'
#   ^ capture a newline in a variable
main $(<$WIFI_DEFAULT); exit

# Copyright (C) 2020 by Tom Davis <tom@greyshirt.net>.
