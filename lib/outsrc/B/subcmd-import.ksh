#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2023-05-08,14.56.27z/2b01187>

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^Upkg^u
	         Copies ^Upkg^u source files to ^Upath^u, updating ^TORIGINS^t and ^T#include <^Upkg^u.h>^t.
	         ^GNote: ^B$PGM^b uses ^Bpkg-config^b variables ^Bsrcfiles^b, ^Bsrctoc^b, or^g
	               ^Gthe ^B--cflags-only-I^b option to discover the source files.^g
	               ^G^Bsrcfiles^b specifies the files exactly (uses brace expansion).^g
	               ^G^Bsrctoc^b specifies the TOC file which contains the file list.^g
	               ^G^B--cflags-only-I^b copies^g ^Uinclude^u^T/^t^Upkg^u^T.^t^O[^o^Tch^t^O]^o^G.^g
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
function try-srcfiles { # {{{1
	local srcfiles
	srcfiles=$(pkg-config --variable srcfiles "$PKGNAME") || return
	[[ -n $srcfiles ]]|| return

	eval "set -A copyfiles -- {$srcfiles}"
} # }}}1
function try-srctoc { # {{{1
	local srctoc
	srctoc=$(pkg-config --variable srctoc "$PKGNAME") || return
	[[ -n $srctoc ]]|| return
	needs-file -or-die "$srctoc"

	NOT-IMPLEMENTED
} # }}}1
function try-cflags { # {{{1
	local f
	set -- $(pkg-config --cflags-only-I "$PKGNAME") || return
	(($#))|| return
	(($#>1))&& {
		warn "More than one include paths for ^B$dPKGNAME^b." "$@"
		return
	 }

	eval "set -A copyfiles -- ${1#-I}/$PKGNAME.{c,h}"
} # }}}1
function do-import { # {{{1
	PKGNAME=$1; desparkle "$1"; dPKGNAME=$REPLY
	pkg-config --exists "$PKGNAME" ||
		die "Package ^B$dPKGNAME^b has no metadata in ^O$^o^VPKG_CONFIG_PATH^v."
	try-srcfiles || try-srctoc || try-cflags ||
		die "Could not discover source files for package ^B$dPKGNAME^b."

	integer errs=0
	for f in "${copyfiles[@]}"; do
		needs-file -or-warn "$f" || ((errs++))
	done
	((errs))&& { warn "Could not ^Bimport^b ^B$dPKGNAME^b."; return; }

showvar copyfiles
	NOT-IMPLEMENTED
} # }}}1
needs warn die pkg-config needs-file

(($#))|| die "Missing ^Upkg^u arguments for ^Iimport^i."
for p; do ( do-import "$p" ); done ; exit

# Copyright (C) 2023 by Tom Davis <tom@greyshirt.net>.
