#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2022-05-04,17.26.12z/54c81ba>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-v^t^] ^[^T-p^t ^Upath^u^] ^[^T-n^t ^Uname^u^] ^[^Upkg-config names^u^]
	         Opens a very simple C skeleton file in ^O\$^o^VVISUAL^v or ^O\$^o^VEDITOR^v,
	         On every save ^Tmake^ts and runs it (saving an unchanged version
	             will clear the ^Imake^i screen, and
	         when the editor is exited, deletes the ^SC^s file.
	         ^T-v^t       Increase verbosity.
	         ^T-p^t ^Upath^u  Use ^Upath^u instead of ^O\$(^o^Tmktemp^t^O)^o. And do not delete
	                  the source file or executable on editor exit.
	         ^T-n^t ^Uname^u  Use this ^Uname^u instead of ^Ttest^t. If ^Uname^u contains a path
	                  implies ^T-p^t with that path.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
verbose=false
filename=test
pathname=
while getopts ':n:p:vh' Option; do
	case $Option in
		n)  filename=$OPTARG;												;;
		p)  pathname=$OPTARG;												;;
		v)	verbose=true;													;;
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
function write-file { #{{{1
	local ldLibsPath=${FROMPWD:?}
	[[ -d $ldLibsPath/obj ]]&& ldLibsPath=$ldLibsPath/obj
	cat <<-===
		/* --------------------------------------------------------------------
		 |  Lines in this comment which look like assignments ('=' or '+=')
		 |    will be treated as such. Other lines are ignored.
		 |  Spaces around '=' or '+=' are not part of the key or value.
		 |  Quote characters have no special meaning.
		 |  Variable expansion in assignments uses shell style (via eval)
		 |  The variable \$PACKAGES, if not empty, will be fed to \`pkg-config\`
		 |    and LDFLAGS and CFLAGS will be appended with that output.
		 + --------------------------------------------------------------------
		    PACKAGES =
		    CFLAGS  += -std=c11
		    CFLAGS  += -Weverything -fdiagnostics-show-option -fcolor-diagnostics
		    # LDLIBS   += $ldLibsPath/my.o
		 + -------------------------------------------------------------------- */

		#include <notify_usr.h> /* sparkle(),message(),inform(),caution(),die() */
		
		#pragma clang diagnostic push
		#pragma clang diagnostic ignored "-Wreserved-id-macro"
		#include <stdio.h>
		#pragma clang diagnostic pop

		int
		main(void)
		{
		    struct {
		        unsigned char  *buf;
		        off_t           size;
		        unsigned char  *p;
		    } x;

		    inform( "sizeof(^Vx^v): ^B%lu^b\n", sizeof(x) );

		    return 0;
		}
		// vim: nofoldenable
	===
} # }}}1
function edit-c-file { #{{{1
	local F
	shquote "$1" F
	${X11TERM:-xterm} -e ksh -c "${VISUAL:-${EDITOR:-vi}} $F" >/dev/null 2>&1
	mv $CFILE $HOLD
} #}}}1
function hh { hN '33;48;5;238' + + "$*"; }
function show-header { hh "$prnPathName @ " $(date +'%H:%M on %A, %B %e'); }
function get-term-size { eval "$(/usr/X11R6/bin/resize)"; }
function clear-screen { print -u2 '\033[H\033[2J\033[3J\033[H\c'; }
function main { #{{{1
	local cksum_previous cksum_current CFILE EXE HOLD
	EXE=$filename
	CFILE=$EXE.c
	HOLD=$(mktemp src-XXXXXX)
	[[ -a $CFILE ]]|| write-file >$CFILE
	edit-c-file "$CFILE" &
	cksum_previous=$(cksum "$CFILE")
	# nvim opening CFILE can trigger watch-file, so wait a moment to
	# avoid a spurious run
	sleep 0.1
	while watch-file "$CFILE" 2>/dev/null; do
		[[ -f $CFILE ]]|| break
		cksum_current=$(cksum "$CFILE")
		[[ $cksum_current == $cksum_previous ]]&& clear-screen
		show-header
		VERBOSE=$verbose build-and-run "$CFILE"
		cksum_previous=$cksum_current
	done
	mv $HOLD $CFILE || die "Could not ^Tmv^t ^U$HOLD^u ^U$CFILE^u."
} #}}}1

needs build-and-run clearout hN needs-cd shquote sparkle-path subst-pathvars watch-file

FROMPWD=$PWD

trap get-term-size WINCH

[[ $filename == */* ]]&& {
	[[ -n ${pathname:-} ]]&&
		die 'Used flags ^T-p^t and ^T-n^t with an included path.'
	pathname=${filename%/*}
	filename=${filename#"$pathname/"}
}

if [[ -z ${pathname:-} ]]; then
	TmpDir=$(mktemp -d) || die 'Could not ^Tmktemp^t.'
	subst-pathvars "$TmpDir" prnPathName
	needs-cd -or-die "$TmpDir"
	trap 'clearout' EXIT
else
	subst-pathvars "$pathname" prnPathName
	needs-cd -or-die "$pathname"
fi
show-header

main; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
