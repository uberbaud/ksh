#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2022-10-27,17.41.05z/523fe30>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

CLIP_START='(--+8<--+)+\[[^]]*\](--+8<--+)+'
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
	^F{4}Usage^f: ^T$PGM^t ^[^Uflags^u^] ^Usrc^u
	         Divvy ^Usrc^u into multiple files where $MARKERS denote
	         embedded files. By default ^Usrc^u will be overwritten without
	         the the embedded files, and the embedded files will be written
	         to the same directory as ^Usrc^u.
	           ^T-D^t  DEBUG: Keep ^Itemporary^i files.
	           ^T-f^t  Force parcelling of possibly not ^BC^b file.
	           ^T-g^t  Put embedded files in ^O$^o^Vxdgdata^v^T/c/^t^{^Tapi^t,^Tsrc^t^}.
	           ^T-k^t  Keep ^Usrc^u as is (don't overwrite).
	           ^T-p^t ^Upath^u  Put embedded files in ^Upath^u.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
keepTemps=false
warnOrDie=die
use_local_c=false
keep_src=false
embedded_out_path=
while getopts ':Dfgkp:h' Option; do
	case $Option in
		D)	keepTemps=true;													;;
		f)	warnOrDie=warn;													;;
		g)	use_local_c=true;												;;
		k)	keep_src=true;													;;
		p)	embedded_out_path=$OPTARG;										;;
		h)	usage;															;;
		\?)	die USAGE "Invalid option: ^B-$OPTARG^b.";						;;
		\:)	die USAGE "Option ^B-$OPTARG^b requires an argument.";			;;
		*)	bad-programmer "No getopts action defined for ^T-$Option^t.";	;;
	esac
done
[[ $use_local_c == true && -n $embedded_out_path ]]&&
	die "^T-g^t and ^T-p^t are mutually exclusive."
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
function get-copyright-from-src	 { # {{{1
	[[ -n ${COPYRIGHT:-} ]]&& return
	COPYRIGHT=$(egrep -o 'Copyright .*' "$SRC")
	[[ $COPYRIGHT == Copyright* ]]|| {
		local year name
		name=$(id -un)
		ERRMSG='User is ^Troot^t.'
		[[ $name != root ]]|| return

		name=$(getent passwd $name|awk -F: '{print $5}')
		ERRMSG='Could not get ^Uname^u for copyright. Try ^Texport^t ^VCOPYRIGHT^v.'
		[[ -n $name ]]|| return

		ERRMSG=
		COPYRIGHT="Copyright (C) $name${EMAIL:+ <$EMAIL>}."
		notify 'Copyright is set to:' "^T$COPYRIGHT^t"
	  }
} # }}}1
function split-on-markers { # {{{1
	split -p "($CLIP_START|$CLIP_END)[[:space:]]*$" "$SRC"
	set -- x??
	ERRMSG="Did not find any markers ($MARKERS)"
	(($#>1))
} # }}}1
function put-h-file { # {{{1
	cat <<-===
	/* $(mk-stemma-header)
	 * -----------------------------------------------------------------------
	 * $fclip: $dscr
	 * -----------------------------------------------------------------------
	 */

	#ifndef $defname
	#define $defname

	===
} # }}}1
function put-non-h-file { # {{{1
	cat <<-===
	/* $(mk-stemma-header)
	 * -----------------------------------------------------------------------
	 *  COPYRIGHT & LICENSE
	 * -----------------------------------------------------------------------
	 *  $COPYRIGHT
	 *
	 *  Permission to use, copy, modify, and distribute this software for any 
	 *  purpose with or without fee is hereby granted, provided that the 
	 *  above copyright notice and this permission notice appear in all 
	 *  copies.
	 *
	 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL 
	 *  WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED 
	 *  WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE 
	 *  AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL 
	 *  DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR 
	 *  PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER 
	 *  TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR 
	 *  PERFORMANCE OF THIS SOFTWARE.
	 * -----------------------------------------------------------------------
	 *  $fclip: $dscr
	 * -----------------------------------------------------------------------
	 */

	===

} # }}}1
function add-includes  { # {{{1
	local qo=\< qc=\>

	(($#==0))&& return

	[[ -n $embedded_out_path ]]&& {
		qo=\"
		qc=\"
	  }
	for hname; do
		print -r -- "#include $qo$hname$qc"
	done
	print
} # }}}1
function handle-clip-start-file { # {{{1
	local pre fclip sep dscr suffix
	[[ $NEXT == START ]]|| {
		ERRMSG="^T$0^t called with NEXT=^T$NEXT^t."
		return 1
	  }
	read -r pre fclip sep dscr
	[[ $fclip == */* ]]&& die "Embedded file name contains a path component."
	[[ $fclip == *.[ch] ]]|| warnOrDie "File may contain other than ^BC^b code."
	[[ ${sep-} == +([[:punct:]]) && -n ${dscr-} ]]&& {
		dscr=${dscr% *}
	  }

	if [[ $fclip == *.h ]]; then
		typeset -u defname=${fclip}_
		gsub . _ $defname defname
		put-h-file
		suffix='\n#endif /* $defname */'
	else
		put-non-h-file
		add-includes *.h
		suffix=
	fi >$fclip

	while IFS= read -r ln; do print -r -- "$ln"; done >>$fclip
	[[ -n ${suffix-} ]]&& print -- "$suffix" >>$fclip
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
			*--8\<--*)	handle-clip-start-file "$x" <$x;	NEXT=END;	;;
			*--\>8--*)	handle-clip-end <$x >$fOUT.tail;	NEXT=START;	;;
			*)			handle-first-file <$x >$fOUT.head;	NEXT=START;	;;
		esac
	done
} # }}}1
function save-embedded-files { # {{{1
	local c h
	for c in *.c; do
		
	done
	for h in *.h; do
	done
} # }}}1

needs needs-file warnOrDie sed

(($#>1))&& die 'Too many parameters. One (^Usrc^u) expected.'
(($#<1))&& die 'Missing required parameter ^Usrc^u.'
[[ $1 == *.c ]]|| warnOrDie "File may contain other than ^BC source code^b."
needs-file -or-die "$1"
SRC=$(realpath "$1" 2>&1) || die "$SRC"
C=${XDG_DATA_HOME:?}/c

if $use_local_c; then
	OUT_C_PATH=$C/src
	OUT_H_PATH=$C/api
elif [[ -n $embedded_out_path ]]; then
	embedded_out_path=$(realpath "$embedded_out_path") # do this before `cd`
	OUT_C_PATH=$embedded_out_path
	OUT_H_PATH=$embedded_out_path
else
	OUT_C_PATH=${SRC%/*}
	OUT_H_PATH=$OUT_C_PATH
fi
needs-path -or-die "$OUT_C_PATH"
needs-path -or-die "$OUT_H_PATH"

needs-cd -with-notice -or-die $(mktemp -d)
$keepTemps || add-exit-actions CleanUp

use-steps

+ get-copyright-from-src	$warnOrDie
+ split-on-markers			$warnOrDie
+ handle-split-files		$warnOrDie
+ save-embedded-files		$warnOrDie
						overwrite_src=$warnOrDie
						$keep_src && overwrite_src=skip
+ overwrite-src				$overwrite_src

do-steps; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
