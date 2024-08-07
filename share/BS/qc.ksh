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
	^F{4}Usage^f: ^T$PGM^t ^[^T-v^t^] ^[^Uname^u^] ^[^Upkg name^u ^S…^s^]
	            Opens a simple C skeleton file in ^O\$^o^VVISUAL^v or ^O\$^o^VEDITOR^v.
	         On every save, ^Tfuddle^t^G+^g^Brun^b it (saving an unchanged version
	         will clear the screen before building).
	            If ^Uname^u is given, that name will be used. If no ^Uname^u is
	         given, ^Ttest.c^t will be created in a temporary directory which will
	         be deleted on quiting the editor. If ^Uname^u does not have a suffix
	         the extension ^T.c^t will be added. It is an error to give a ^Uname^u with
	         a suffix other than ^T.c^t.
	            Any ^Upkg name^us given will be placed in ^O$^o^VPACKAGES^v for ^Tfuddle^ting.
	         If ^Uname^u is a valid installed ^Tpkg-config^t package, it will be
	         interpreted as a ^Upkg name^u, adding a ^T.c^t suffix will prevent that.

	             ^T-v^t       Increase verbosity.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
verbose=false
filename=
pathname=
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
function write-file { #{{{1
	local o objs OBJS
	objs=$OBJDIR/*.o
	[[ $objs == $OBJDIR/\*.o ]]|| for o in $objs; do
		OBJS=${OBJS:+"$OBJS "}${o##*/}
	done
	subst-pathvars $CURDIR CURDIR
	subst-pathvars $OBJDIR OBJDIR
	cat <<-===
		/* ----------------------------------------------------------------------
		 | $(mk-stemma-header)
		 | ----------------------------------------------------------------------
		 |     Lines in THIS comment which look like \`make\` assignments,
		 |  when processed by \`fuddle\`, will be stripped of leading whitespace
		 |  then passed to \`make\` to compile this file.
		 |     The variable \$PACKAGES, if not empty, will be fed to \`pkg-config\`
		 |  and \$LDFLAGS and \$CFLAGS will be appended with that output.
		 |     Files named in \$OBJS and found in \$OPATH will be added to \$LDLIBS.
		 + ----------------------------------------------------------------------
		    # CC       = include-what-you-use
		    # SRCPATH  = ${CURDIR:-}
		    # OPATH    = ${OBJDIR:-}
		    # OBJS     = ${OBJS:-my.o}
		    # ^equivalent to: LDLIBS   += \$OPATH/my.o
		    PACKAGES = notify_usr${*+ $*}
		    CFLAGS  += -std=c17 -Wno-unsafe-buffer-usage
		 + -------------------------------------------------------------------- */

		#include <notify_usr.h> /* sparkle(),message(),inform(),caution(),die() */
		#include <dbg_chkpnt.h> /* DBG_CHKPNT, DBG_LOGIT(msg) */
		
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

needs add-exit-actions build-and-run clearout needs-cd pkg-config use-app-paths
use-app-paths build-tools
needs get-build-paths subst-pathvars

set -A PACKAGES --
set -A BAD --
integer i=0 b=0
while (($#)); do
	if pkg-config --exists "$1"; then
		PACKAGES[i++]=$1
	elif [[ -z $filename ]]; then
		filename=$1
	else
		BAD[b++]=$1
	fi
	shift
done
((b))&& die 'Uninstalled or bad ^Bpkg-config^b packages:' "${BAD[@]}"

get-build-paths "$PWD" # set before cd-ing somewhere else.

if [[ -z ${filename-} ]]; then
	filename=test
elif [[ $filename == */* ]]; then
	pathname=${filename%/*}
	filename=${filename#"$pathname/"}
	needs-cd -or-die "$pathname"
else
	pathname=$PWD
fi

if [[ -z ${pathname:-} ]]; then
	pathname=$(mktemp -td qc.XXXXXXXXXX) || die 'Could not ^Tmktemp^t.'
	needs-cd -or-die "$pathname"
	add-exit-actions 'clearout'
fi

[[ $filename == *.* && $filename != *.c ]]&&
	die "Extension ^B${filename#*.}^b is not valid. Must be ^T.c^t if given."

filename=${filename%.c}.c
[[ -a $filename ]]&& {
	sparkle-path "$PWD/$filename"
	die "$REPLY already exists." "See: ^Tbuild-and-run -e^t"
  }

write-file "$@" >$filename
exec build-and-run -e "$filename"

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
