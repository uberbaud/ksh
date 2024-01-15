#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2024-01-08,16.41.13z/43d8242>

# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-C^t ^Upath^u^] ^[^T-v^t^]
	         Update files in ^BORIGINS^b
	           ^T-C^t ^Upath^u  Change to ^Upath^u before processing.
	           ^T-v^t       verbose
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
while getopts ':C:vh' Option; do
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
function update-file { # {{{1
	local origin copy
	eval origin="$1"
	copy=$2
	needs-file -or-warn "$origin" || return
	[[ $origin -nt $copy ]]&& {
		$VERBOSE && notify "^Tcp -f^t ^U$origin^u ^U$copy^u"
		command cp -f "$origin" "$copy" ||
			warn "could not update ^V$copy^v."
	  }
} # }}}1
function do-copies { # {{{1
	[[ -s ORIGINS ]]|| return 0
	integer i=0 h=0 u=0
	while IFS=$TAB read copy orig; do
		((i++))
		[[ ${copy:-#} == \#* ]]&& continue
		if [[ -n $orig ]]; then
			[[ $copy == *.h ]]&& hFiles[h++]=$copy
			if update-file "$orig" "$copy"; then
				[[ $copy == *.[ch] ]]&&
					updFiles[u++]=$copy
			else
				((++errs))
			fi
		else
			warn "SYNTAX ERROR: line $i, missing original file."
		fi
	done <ORIGINS
	return $errs
} # }}}1
function escape-ere-metachars { # {{{1
	local old=$1
	typeset -L1 c
	REPLY=
	while ((${#old})); do
		c=$old		# just the first byte
		old=${old#?}
		[[ $c == [{}\|\(\)^\$\*.+\[\]] ]]&&
			REPLY=$REPLY\\
		REPLY=$REPLY$c
	done
} # }}}1
function cvt-angles-to-quotes { # {{{1
	local ws eds
	eds=
	for hname in "${hFiles[@]}"; do
		escape-ere-metachars "$hname"
		eds=$eds\|$REPLY
	done
	ws='[[:space:]]'
	eds="/^($ws*#$ws*include$ws+)<(${eds#\|})>/s//\1\"\2\"/"
	set -- sed -i -E -e "$eds" "${updFiles[@]}"
	$VERBOSE && { print -n -- '   > '; prn-cmd "$@"; }
	"$@"
} # }}}1
function main { # {{{1
	integer errs=0
	set -A hFiles --
	set -A updFiles --

	do-copies
	((${updFiles[*]+1}))&& cvt-angles-to-quotes

	return $errs
} #}}}1

needs needs-file needs-path

needs-file -or-die ORIGINS
TAB='	'

main; exit

# Copyright (C) 2024 by Tom Davis <tom@greyshirt.net>.
