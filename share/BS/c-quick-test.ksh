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
	^F{4}Usage^f: ^T$PGM^t ^[^T-v^t^[
	         Opens a very simple C skeleton file in ^O\$^o^VVISUAL^v or ^O\$^o^VEDITOR^v,
	         On every save ^Tmake^ts and runs it (saving an unchanged version
	             will clear the ^Imake^i screen,
	         and when the editor is exited, deletes the ^SC^s file.
	         ^T-v^t  Increase verbosity.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
verbose=false
while getopts ':vh' Option; do
	case $Option in
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
MARK=' + --------------------------------------------------------------------'
function write-file { #{{{1
	cat <<-===
		/* --------------------------------------------------------------------
		 |  Lines in the following comment will be treated as \`make\` style 
		 |    variable assignments ('=' or '+=').
		 |  Quotes are neither needed nor supported.
		 |  Variable expansion is NOT supported in assignments.
		 |  Lines can be commented out by prefixing them with '#'.
		 |  The variable \$PACKAGES, if not empty, will be fed to \`pkg-config\`
		 |    and LDFLAGS and CFLAGS will be appended with that output.
		$MARK
		    PACKAGES =
		    CFLAGS  += -std=c11
		    CFLAGS  += -Weverything -fdiagnostics-show-option -fcolor-diagnostics
		    # LDFLAGS  += $FROMPWD/my.o
		$MARK */

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
	local TAB='	' line key value

	# skip to actual variable declarations
	while IFS== read -r line; do
		[[ $line == $MARK ]]&& break
	done

	# process variables
	while IFS== read -r key value; do
		[[ $key == $MARK* ]]&& break

		key=${key##*([ $TAB])}
		[[ $key == \#* ]]&& continue

		if [[ $key == *+ ]]; then
			key=${key%%*([ $TAB])+}
			eval value="\${$key:+\"\$$key \"}\$value"
		else
			key=${key%%*([ $TAB])}
		fi
		eval $key=\$value

		$verbose && notify "$key" "$value"
		export $key
	done
	[[ -z ${PACKAGES:-} ]]|| {
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
function hh { # {{{1
	hN '33;48;5;238' + + "$*"
} # }}}1
function show-header { # {{{1
	# remove leading spaces using set and $*
	hh "$prnTmpDir @ " $(date +'%H:%M on %A, %B %e')
} # }}}1
function get-term-size { eval "$(/usr/X11R6/bin/resize)"; }
function clear-screen { print -u2 '\033[H\033[2J\033[3J\033[H\c'; }
function build-and-run { # {{{2
	show-header
	get-set-vars <$CFILE	|| return # die if pkg-config error
	make "$EXE"				|| return

	hh "running $EXE"
	time ./"$EXE"
	hh "$EXE completed // rc = $?"
} # }}}2
function main { #{{{1
	local cksum_previous cksum_current CFILE EXE
	EXE=test
	CFILE=$EXE.c
	write-file >$CFILE
	edit-c-file "$CFILE" &
	cksum_previous=$(cksum "$CFILE")
	while watch-file "$CFILE" 2>/dev/null; do
		[[ -f $CFILE ]]|| break
		cksum_current=$(cksum "$CFILE")
		[[ $cksum_current == $cksum_previous ]]&& clear-screen
		(build-and-run) # in a subshell so variables are "reset"
		cksum_previous=$cksum_current
	done
	true
} #}}}1

needs clearout hN h2 needs-cd shquote sparkle-path subst-pathvars watch-file

FROMPWD=$PWD

trap get-term-size WINCH

TmpDir=$(mktemp -d) || die 'Could not ^Tmktemp^t.'
subst-pathvars "$TmpDir" prnTmpDir
needs-cd -or-die "$TmpDir"
trap 'clearout' EXIT
show-header

main; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
