#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2022-06-27,07.47.02z/aca08e>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

MAKE=/usr/bin/make

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-p^t^] ^Uc source^u
	         ^Tmake^t with ^Teval^t ^O\$(^o^Tget-header-vars^t^O)^o
	           ^T-p^t  Pass ^T-p^t to ^Tmake^t
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
opts=
while getopts ':ph' Option; do
	case $Option in
		p)	opts=-p;														;;
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
function get-make-header { # {{{1
	local SpTab
	SpTab=' 	'

	IFS=$SpTab read -r line || die "Bad read on ^SSTDIN^s (^B$source^b)."
	[[ $line == /\** ]]|| die 'No fuddle-style (^Tmake^t) header.'

	while :; do
		[[ $line == *\*/* ]]&& break # end of comment
		[[ $line == ?(.)[A-Za-z_]*([A-Za-z0-9_])*([$SpTab])?(+)=* ]]&&
			print -r -- "$line"
		IFS=$SpTab read -r line || break
	done
} # }}}1

needs needs-file

(($#))||	die 'Missing required parameter ^Uc source^u.'
(($#>1))&&	die 'Too many parameters. Expected only ^Uc source^u.'

target=${1%.c}
source=$target.c
needs-file -or-die "$source"

# use environment CFLAGS, BUT don't duplicate the bits we set in the
# heredoc makefile.
cflags=
for c in ${CFLAGS:-}; do
	[[ ${c#-} == @(Weverything|fdiagnostics-show-option|fcolor-diagnostics) ]]&&
		continue
	cflags="${cflags+ }$c"
done
unset CFLAGS

$MAKE -f - $opts $target <<----
	CFLAGS = -Weverything -fdiagnostics-show-option -fcolor-diagnostics ${cflags-}
	$(get-make-header <$source)
	.ifdef OPATH
	OBJS         := \$(OBJS:S|^|\$(OPATH)/|)
	.endif
	.ifdef OBJS
	LDLIBS      +:= \$(OBJS)
	.endif
	.ifdef PACKAGES
	PKG_CFLAGS  +!= pkg-config --cflags \$(PACKAGES)
	PKG_LDFLAGS +!= pkg-config --libs \$(PACKAGES)
	.endif
	CFLAGS      +:= \$(PKG_CFLAGS)
	LDFLAGS     +:= \$(PKG_LDFLAGS)
	---

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
