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
	^F{4}Usage^f: ^T$PGM^t
	         Opens a very simple C skeleton file in ^O\$^o^VVISUAL^v or ^O\$^o^VEDITOR^v,
	         On every save ^Tmake^ts and runs it (saving an unchanged version
	             will clear the ^Imake^i screen,
	         and when the editor is exited, deletes the ^SC^s file.
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
function write-file { #{{{1
	cat <<-\===
		/* -------------------------------------------------------------------- *\
		|*  Lines beginning with //: (comments) will be treated as `make` style *|
		|*  variable assignments ('=' or '+=', no quotes needed nor supported). *|
		|*  Variable expansion is NOT supported in assignments.                 *|
		|*  The variable $PACKAGES, if not empty, will be fed to `pkg-config`   *|
		|*  and LDFLAGS and CFLAGS will be appended with that output.           *|
		\* -------------------------------------------------------------------- */
		//: PACKAGES =
		//: CFLAGS  += -std=c11
		//: CFLAGS  += -Weverything -fdiagnostics-show-option -fcolor-diagnostics

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
function get-set-vars { # {{{1
	local TAB='	' key value
	while IFS== read -r key value; do
		[[ $key == //:* ]]|| continue
		key=${key##//:*([ $TAB])}
		if [[ $key == *+ ]]; then
			key=${key%%*([ $TAB])+}
			eval value="\${$key:+\"\$$key \"}\$value"
		else
			key=${key%%*([ $TAB])}
		fi
		eval $key=\$value

		[[ -n $DEBUG ]]&& notify "$key" "$value"
		export $key
	done <$1
	[[ -z $PACKAGES ]]|| {
		pkg-config --exists $PACKAGES || return
		CFLAGS=${CFLAGS:+"$CFLAGS "}$(pkg-config --cflags $PACKAGES)
		LDFLAGS=${LDFLAGS:+"$LDFLAGS "}$(pkg-config --libs $PACKAGES)
		export CFLAGS LDFLAGS
	  }
} # }}}1
function edit-c-file { #{{{1
	local F
	shquote "$1" F
	${X11TERM:-xterm} -e ksh -c "${VISUAL:-${EDITOR:-vi}} $F" >/dev/null 2>&1
	rm -f $CFILE
} #}}}1
function get-term-size { eval "$(/usr/X11R6/bin/resize)"; }
function clear-screen { print -u2 '\033[H\033[2J\033[3J\033[H\c'; }
function main { #{{{1
	local cksum_A cksum_B CFILE EXE
	EXE=test
	CFILE=$EXE.c
	write-file >$CFILE
	edit-c-file "$CFILE" &
	cksum_A=$(cksum "$CFILE")
	while watch-file "$CFILE" 2>/dev/null; do
		[[ -f $CFILE ]]|| break
		cksum_B=$(cksum "$CFILE")
		if [[ $cksum_A == $cksum_B ]]; then
			clear-screen
			h1 "$TMPDIR"
		else
			cksum_A=$cksum_B
		fi
		set -- $(date +'%H:%M on %A, %B %e')
		h1 "$*"
		get-set-vars "$CFILE" && make "$EXE" && {
			h2 "running $EXE"
			./"$EXE"
		  }
	done
} #}}}1

needs clearout h1 h2 shquote sparkle-path watch-file

trap get-term-size WINCH

TMPDIR=$(mktemp -d) || die 'Could not ^Tmktemp^t.'
builtin cd "$TMPDIR" || {
	sparkle-path "$TMPDIR"
	die "Could not ^Tcd^t to $REPLY."
  }
trap 'clearout -f' EXIT
h1 "$TMPDIR"

main; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
