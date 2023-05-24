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
	^F{4}Usage^f: ^T$PGM^t ^[^T-p^t ^Uto-path^u^] ^Upkg^u
	         Copies ^Upkg^u source files to ^Upath^u, updating ^TORIGINS^t and ^T#include <^Upkg^u.h>^t.
	           ^T-p^t  Copy to ^Uto-path^u instead of to current working directory.
	         ^GNote: ^B$PGM^b uses ^Bpkg-config^b variables ^Bsrcfiles^b, ^Bsrctoc^b, or^g
	               ^Gthe ^B--cflags-only-I^b option to discover the source files.^g
	               ^G^Bsrcfiles^b specifies the files exactly (uses brace expansion).^g
	               ^G^Bsrctoc^b specifies the TOC file which contains the file list.^g
	               ^G^B--cflags-only-I^b copies^g ^Uinclude^u^T/^t^Upkg^u^T.^t^O[^o^Tch^t^O]^o^G.^g
	       ^T$PGM -u^t ^[^T-p^t ^Uorigins-file-path^u^]
	         Updates source files given in ^TORIGINS^t file when origin is newer.
	           ^T-p^t  Find ^TORIGINS^t file in ^Uorigins-file-path^u instead of the
	               current working directory.
	       ^T$PGM -l^t
	         Lists packages present in ^O$^o^VPKG_CONFIG_PATH^v paths.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
list_pc_files=false
do_update=false
with_path=
while getopts ':lup:h' Option; do
	case $Option in
		l)	list_pc_files=true;												;;
		u)	do_update=true;													;;
		p)	with_path=$OPTARG;												;;
		h)	usage;															;;
		\?)	die USAGE "Invalid option: ^B-$OPTARG^b.";						;;
		\:)	die USAGE "Option ^B-$OPTARG^b requires an argument.";			;;
		*)	bad-programmer "No getopts action defined for ^T-$Option^t.";	;;
	esac
done
$list_pc_files && $do_update &&
	die '^T-l^t and ^T-u^t cannot be used together.'
$list_pc_files && [[ -n ${with_path:-} ]]&&
	die '^T-p^t cannot be used with ^T-l^t.'
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
function get-pkg-meta-files { # {{{1
	local p s an
	[[ -n ${PKG_CONFIG_PATH:-} ]]|| die "^O$^o^VPKG_CONFIG_PATH^v is not set."
	splitstr : "$PKG_CONFIG_PATH" cfgpaths
	new-array bad_paths good_paths metafiles
	for p in "${cfgpaths[@]}"; do
		if [[ -d $p ]]; then
			+good_paths "$p"
		else
			sparkle-path "$p"
			+bad_paths "$REPLY"
		fi
	done
	bad_paths-not-empty && {
		s=; an=' an'
		[[ ${#bad_paths[*]} -gt 1 ]]&& { s=s; an=; }
		warn "^VPKG_CONFIG_PATH^v contains$an invalid path$s." "${bad_paths[@]}"
  	}

	good_paths-is-empty &&
		die "^VPKG_CONFIG_PATH^v does not contain any valid paths."

	bad_paths-reset
	for p in "${good_paths[@]}"; do
		set -- $p/*.pc
		if [[ $1 == $p/\*.pc ]]; then
			sparkle-path "$p"
			+bad_paths "$REPLY"
		else
			+metafiles "$@"
		fi
	done

	bad_paths-not-empty && {
		s=; an=' a'
		[[ ${#bad_paths[*]} -gt 1 ]]&& { s=s; an=; }
		warn \
			"^VPKG_CONFIG_PATH^v contains$an path$s with no ^O*^o^T.pc^t files." \
			"${bad_paths[@]}"
  	}

	metafiles-is-empty && {
		local msg
		msg="There are no paths in ^VPKG_CONFIG_PATH^v"
		msg="$msg with any ^O*^o^T.pc^t files."
		die "$msg"
	  }

} # }}}1
function list-available-packages { # {{{1
	get-pkg-meta-files
	for m in "${metafiles[@]}"; do
		m=${m##*/}
		print "  ${m%.pc}"
	done
} # }}}1
function do-update { # {{{1
	NOT-IMPLEMENTED
} # }}}1
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
needs splitstr new-array sparkle-path warn die needs-path pkg-config needs-file

[[ -n ${with_path:-} ]]&& needs-path -or-die "$with_path"

if $list_pc_files; then
	(($#))&& die "Did not expect arguments for ^T-l^t (^Ilist-pc-files^i)"
	list-pc-files
elif $do_update; then
	(($#))&& die "Did not expect arguments for ^T-u^t (^Iupdate^i)"
	do-update
else
	(($#))|| die "Missing ^Upkg^u arguments for ^Iimport^i."
	for p; do ( do-import "$p" ); done
fi; exit

# Copyright (C) 2023 by Tom Davis <tom@greyshirt.net>.
