#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2022-10-27,17.41.05z/523fe30>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

CLIP_START='(--+8<--+)+\[[[:space:]]*[^[:space:]]+[[:space:]]*\](--+8<--+)+'
CLIP_END='(--+>8--+)+'
MARKERS='^T--8<--^t and ^T-->8--^t'
fOUT=C_SOURCE_CODE

# Usage {{{1
warOrDie=die
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Divvy a file into multiple files using $MARKERS
	           ^T-f^t  Force parcelling of possibly not ^BC^b file.
	           ^T-k^t  Keep ^Itemporary^i files.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
keepTemps=false
warnOrDie=die
while getopts ':fhk' Option; do
	case $Option in
		f)	warnOrDie=warn;													;;
		h)	usage;															;;
		k)	keepTemps=true;													;;
		\?)	die USAGE "Invalid option: ^B-$OPTARG^b.";						;;
		\:)	die USAGE "Option ^B-$OPTARG^b requires an argument.";			;;
		*)	bad-programmer "No getopts action defined for ^T-$Option^t.";	;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
function CleanUp { # {{{1
	local P
	[[ $PWD == $TMPDIR/* ]]|| {
		warn "^O\$^o^VPWD^v is not in ^O\$^o^VTMPDIR^v." "Not cleaning ^B$PWD^B"
		return
	}
	$keepTemps && return
	rm -f *
	P=$PWD
	cd /
	rmdir "$P"
} # }}}1
function split-on-markers { # {{{1
	split -p "($CLIP_START|$CLIP_END)[[:space:]]*$" "$SRC"
	set -- x??
	ERRMSG="Did not find any markers ($MARKERS)"
	(($#>1))
} # }}}1
function handle-clip-start-file { # {{{1
	local fclip
	[[ $NEXT == START ]]|| {
		ERRMSG="^T$0^t called with NEXT=^T$NEXT^t."
		return 1
	  }
	(($#==3))|| {
		ERRMSG="^B$1^b ^BCLIP_START^b has an unexpected format."
		return 1
	  }
	fclip=$2
	[[ $fclip == */* ]]&& {
		ERRMSG='Output file name contains a path component.'
		return 1
	  }
	[[ $fclip == *.[ch] ]]|| {
		ERRMSG="^B$fclip^b has an unexpected ^Iext^i."
		return 1
	  }
	IFS= read -r ln # skip 1st line (CLIP_START)
	while IFS= read -r ln; do print -r -- "$ln"; done >$fclip
} # }}}1
function handle-clip-end { # {{{1
	[[ $NEXT == FIRST ]]|| {
		ERRMSG="^T$0^t called with NEXT=^T$NEXT^t."
		return 1
	  }
	IFS= read -r ln # skip 1st line (CLIP_END)
	# SKIP BLANK LINES
	while IFS= read -r ln; do
		[[ $ln != *([[:space:]]) ]]&& break
	done
	print				# print one (1) blank line
	print -r -- "$ln"	# print first non-blank line
	while IFS= read -r ln; do print -r -- "$ln"; done
} # }}}1
function handle-first-file { # {{{1
	[[ $NEXT == FIRST ]]|| "^T$0^t called with NEXT=^T$NEXT^t."
	while IFS= read -r ln; do print -r -- "$ln"; done >$fOUT.head
} # }}}1
function handle-split-files { #{{{1
	NEXT=FIRST
	for x in x??; do 
		IFS= read -r ln <$x
		case $ln in
			*--8\<--*)	handle-clip-start-file $ln <$x;		NEXT=END;	;;
			*--\>8--*)	handle-clip-end <$x >$fOUT.tail;	NEXT=START;	;;
			*)			handle-first-file <$x >$fOUT.head;	NEXT=START;	;;
		esac
	done
} # }}}1

needs needs-file warnOrDie sed

(($#>1))&& die 'Too many parameters. One (^Usrc^u) expected.'
(($#<1))&& die 'Missing required parameter ^Usrc^u.'
[[ $1 == *.c ]]|| warnOrDie "File may contain other than ^BC source code^b."
needs-file -or-die "$1"
SRC=$(realpath "$1" 2>&1) || die "$SRC"

needs-cd -with-notice -or-die $(mktemp -d)
$keepTemps || add-exit-actions CleanUp

use-steps

+ split-on-markers		$warnOrDie
+ handle-split-files	$warnOrDie

do-steps; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
