#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2022-06-27,07.47.02z/aca08e>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

MAKE=/usr/bin/make

WarnLevel=${WARN_LEVEL:-everything}
# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^Umake opts^u^] ^UC source^u ^[^T-^t^]
	         Ignoring any ^Imakefile^i, ^Tmake^t using vars from the ^UC source^u header.^N*^n
	           ^T-^t Print created ^Imakefile^i but do not ^Tmake^t.
	           Passes ^T-W^t^O\${^o^VWARN_LEVEL^v^O:-^o^Teverything^t^O}^o ^G(Currently^g ^T$WarnLevel^t^G)^g to ^O\$^o^VCC^v.
	       ^T$PGM -h^t
	         Show this help message.
	   ^G____^g
	   ^N*^n^GLines in the ^UC source^u header comment that look like^g ^Tmake^t ^Gassignments^g
	    ^Gare used as such. Plus, for convenience,^g
	    ^G1) the variable^g ^O\$^o^VPACKAGES^v^G, if not empty, will be fed to^g ^Tpkg-config^t^G,^g
	       ^Gand^g ^O\$^o^VLDFLAGS^v ^Gand^g ^O\$^o^VCFLAGS^v ^Gwill be appended with that output; and^g
	    ^G2) Files named in^g ^O\$^o^VOBJS^v^G, found in^g ^O\$^o^VOPATH^v ^Gwill be added to^g ^O\$^o^VLDLIBS^v^G.^g
	===SPARKLE===
	exit 0
} # }}}
function get-header-assignments { # {{{1
	local SpTab
	SpTab=' 	'

	IFS=$SpTab read -r line || die "Bad read on ^SSTDIN^s (^B$source^b)."
	[[ $line == /\** ]]|| die 'No fuddle-style (^Tmake^t) header.'

	while :; do
		[[ $line == *\*/* ]]&& break # end of comment
		[[ $line == ?(.)[A-Za-z_]*([A-Za-z0-9_])*([$SpTab])*([+:?!])=* ]]&&
			print -r -- "$line"
		IFS=$SpTab read -r line || break
	done
} # }}}1

dryrun=false
[[ ${1:-} == -h ]]&& usage

needs needs-file header-line needs-cd

ERR_MISSING_SRC='Missing required parameter ^Uc source^u.'
(($#))||	die "$ERR_MISSING_SRC"

# move everything but the last into mkopts
set -A mkopts --
mkopt_count=0
while (($#>1)); do
	mkopts[mkopt_count++]=$1
	shift
done
# if the last thing is the dry-run dash, use the next-to-last as the
# last and note that we want a dry-run
[[ $1 == - ]]&& {
	dryrun=true
	((mkopt_count--))|| die "$ERR_MISSING_SRC"
	set -- "${mkopts[mkopt_count]}"
	unset mkopts[mkopt_count]
}

# allow for a source or target as the file name
if [[ $1 == *.c ]]; then
	target=${1%.c}
	source=$1
else
	target=$1
	source=${target%.*}.c
fi
needs-file -or-die "$source"
[[ $target == */* ]]&& {
	needs-cd -or-die -with-notice "${target%/*}"
	target=${target##*/}
  }

# Remove from CFLAGS the bits we set in the heredoc makefile.
[[ -n ${CFLAGS:-} ]]&& {
	cflags=
	for c in ${CFLAGS:-}; do
		[[ ${c#-} == @(Wall|Weverything|fdiagnostics-show-option|fcolor-diagnostics) ]]&&
			continue
		cflags="${cflags+ }$c"
	done
	CFLAGS=${cflags:-}
	[[ -z $CFLAGS ]]&& unset CFLAGS
  }

# what are we doing, and what are we doing it with
hhhSource=" From <$source> header"
hhhStandard=" The standard bits"
if $dryrun; then
	set -- cat
	hhhSource=$(header-line 67 ═ ╡ ╞ "$hhhSource ")
	hhhStandard=$(header-line 67 ═ ╡ ╞ "$hhhStandard ")
elif ((mkopt_count)); then
	set $MAKE -f - "${mkopts[@]}" "$target"
else
	set $MAKE -f - "$target"
fi

# Well then, do it.
"$@" <<- ───────────
	#${hhhSource-}
	$(get-header-assignments <$target.c)

	#${hhhStandard-}
	# Show all the bits and do it in color.
	CFLAGS += -W$WarnLevel -fdiagnostics-show-option -fcolor-diagnostics

	# handle OPATH/OBJS
	.if defined(OPATH) && !empty(OPATH)
	OBJS         := \$(OBJS:S|^|\$(OPATH)/|)
	.endif
	.if defined(OBJS) && !empty(OBJS)
	LDLIBS      +:= \$(OBJS)
	.endif

	# handle PACKAGES
	.if defined(PACKAGES) && !empty(PACKAGES)
	PKG_CFLAGS  +!= pkg-config --cflags \$(PACKAGES)
	PKG_LDFLAGS +!= pkg-config --libs \$(PACKAGES)
	CFLAGS      +:= \$(PKG_CFLAGS)
	LDFLAGS     +:= \$(PKG_LDFLAGS)
	.endif
───────────

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
