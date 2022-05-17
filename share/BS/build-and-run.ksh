#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2022-05-17,20.16.23z/461e7f5>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^Usrc^u
	         Uses header information in C file to set build environment,
	         runs ^Tmake^t ^O\${^o^Vsrc^v^O%^o^T.c^t^O}^o, and
	         runs the resulting executable.
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
function hh { hN '33;48;5;238' + + "$*"; }
function show-get-set { print -ru2 -- "${1:?} = ${2:-}"; }
function first-time-get-set { # {{{1
	hh 'GET and SET variables'
	show-get-set "$1" "$2"
	showvar_fn=show-get-set
} # }}}1
function get-set-vars { # {{{1
	local TAB='	' line key value

	IFS= read line
	[[ $line == /\** ]]|| {
		warn \
			"In order to ^Bget^b and ^Bset^b variables, the first line"	\
			"^BMUST^b be the opening of a multi-line comment, but it"	\
			"isn't, so we're not setting the ^Tmake^t environment."
		return 0 # not a FATAL ERROR, so return OK
	  }

	# process variables
	while IFS=" $TAB" read -r line; do
		[[ $line == *\*/* ]]&& break # end of comment
		[[ $line == [A-Za-z_]*([A-Za-z0-9_])*([ $TAB])?(+)=* ]]|| continue

		# there's definitely an equals sign, we just tested, so we're
		# good
		key=${line%%=*}
		value=${line##"$key="*([ $TAB])}

		if [[ $key == *+ ]]; then
			key=${key%%*([ $TAB])+}
			eval value="\${$key:+\"\$$key \"}\$value"
		else
			key=${key%%*([ $TAB])}
		fi
		eval $key=\$value

		$showvar_fn "$key" "$value"
		export $key
	done
	[[ -z ${PACKAGES:-} ]]|| {
		pkg-config --exists $PACKAGES || return
		CFLAGS=${CFLAGS:+"$CFLAGS "}$(pkg-config --cflags $PACKAGES)
		LDFLAGS=${LDFLAGS:+"$LDFLAGS "}$(pkg-config --libs $PACKAGES)
		export CFLAGS LDFLAGS
	  }
} # }}}1
function main { # {{{1
	get-set-vars <$CFILE	|| return # die if pkg-config error
	hh "make $EXE"
	make "$EXE"				|| return

	hh "running $EXE"
	time ./"$EXE"
	hh "$EXE completed // rc = $?"
} # }}}1

(($#))|| die 'Missing required argument ^Usrc^u.'
(($#==1))|| die 'Too many arguments. Expected only ^Usrc^u.'

needs hN needs-cd

# HANDLE VERBOSITY
typeset -l verbose=${VERBOSE:-false}
if [[ $verbose == @(no|false|0) ]]; then
	showvar_fn=:
else
	showvar_fn=first-time-get-set
fi

# HANDLE OTHERWHERE source file
filename=$1
[[ $filename == */* ]]&& {
	pathname=${filename%/*}
	filename=${filename#"$pathname/"}
	needs-cd -or-die "$pathname"
}

EXE=${filename%.c}
CFILE=$EXE.c

main; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
