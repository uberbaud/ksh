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
filename=
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
	local o objs OBJS
	objs=$OBJDIR/*.o
	[[ $objs == $OBJDIR/\*.o ]]|| for o in $objs; do
		OBJS=${OBJS:+"$OBJS "}${o##*/}
	done
	subst-pathvars $CURDIR CURDIR
	subst-pathvars $OBJDIR OBJDIR
	cat <<-===
		/* --------------------------------------------------------------------
		 | $(mk-stemma-header)
		 | --------------------------------------------------------------------
		 |  Lines in this comment which look like make assignments ([+:?!]=)
		 |    will be passed to \`make\`.
		 |  The variable \$PACKAGES, if not empty, will be fed to \`pkg-config\`
		 |    and \$LDFLAGS and \$CFLAGS will be appended with that output.
		 |  Files named in \$OBJS and found in \$OPATH will be added to \$LDLIBS
		 + --------------------------------------------------------------------
		    # SRCPATH  = ${CURDIR:-}
		    # OPATH    = ${OBJDIR:-}
		    # OBJS     = ${OBJS:-my.o}
		    # ^equivalent to: LDLIBS   += \$OPATH/my.o
		    PACKAGES = notify_usr${*+ "$*"}
		    CFLAGS  += -std=c11
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
function validate-packages { # {{{1
	local p i

	(($#==0))&& return

	pkg-config --exists "$@" || {
		i=0
		set -A badPackages --
		for p; do
			pkg-config --exists "$p" || badPackages[i++]=$p
		done
		die "Unknown packages:" "${badPackages[@]}"
	  }

	return $i
} # }}}1

needs add-exit-action build-and-run clearout needs-cd use-app-paths pkg-config

validate-packages "$@"

if [[ -z ${filename-} ]]; then
	filename=test
elif [[ $filename == */* ]]; then
	[[ -n ${pathname:-} ]]&&
		die 'Used flags ^T-p^t and ^T-n^t with an included path.'
	pathname=${filename%/*}
	filename=${filename#"$pathname/"}
else # -n with bare filename (no path)
	pathname=$PWD
fi

ORIGINAL_PWD=$PWD
if [[ -z ${pathname:-} ]]; then
	pathname=$(mktemp -d) || die 'Could not ^Tmktemp^t.'
	needs-cd -or-die "$pathname"
	add-exit-action 'clearout'
else
	needs-cd -or-die "$pathname"
fi

filename=${filename%.c}.c
[[ -a $filename ]]&& {
	sparkle-path "$PWD/$filename"
	die "$REPLY already exists." "See: ^Tbuild-and-run -e^t"
  }

use-app-paths build-tools
needs get-build-paths
get-build-paths "$ORIGINAL_PWD"

write-file "$@" >$filename
build-and-run -e "$filename"; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
