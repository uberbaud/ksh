#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2024-01-15,02.13.55z/1d6b406>
set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Lists packages present in ^O$^o^VPKG_CONFIG_PATH^v paths.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
while getopts ':lup:h' Option; do
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
function main { # {{{1
	get-pkg-meta-files
	for m in "${metafiles[@]}"; do
		m=${m##*/}
		print "  ${m%.pc}"
	done
} # }}}1
needs splitstr new-array sparkle-path warn die

[[ -n ${CD_TO_PATH:-} ]]&&
	die "Can not use ^T-C^T ^Upath^u with ^Blist^b sub-command."

main; exit

# Copyright (C) 2023 by Tom Davis <tom@greyshirt.net>.
