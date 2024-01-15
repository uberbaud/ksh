#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2024-01-09,23.01.14z/468ad21>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
this_pgm=${0##*/}
desparkle "$this_pgm"
PGM=$REPLY
function help-usage { # {{{1
	sparkle >&2 <<-\
	===SPARKLE===
	       ^T$PGM -h^t^|^Thelp^t ^[^Usubcmd^u^]
	         Show this help message, or help for ^Usubcmd^u.
	===SPARKLE===
	exit 0
} # }}}1
function usage { # {{{1
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-C^t ^Upath^u^] ^[^T-v^t^] ^Usubcmd^u ^S…^s
	         Handles dependency imports into current source tree and updates of
	         those imports as well as maintenance of ^BORIGINS^b file.
	           ^T-C^t ^Upath^u  Change to ^Upath^u before processing.
	           ^T-v^t       Be verbose.
	       ^T$PGM^t ^[^UOPTIONS^u^] ^Timport^t ^Ufile1^u ^[^UfileN^u ^S…^s^]
	         Import files using ^Tpkg-config^t variables ^Vsrcfiles^v, ^Vsrctoc^v,
	         or the ^T--cflags-only-I^t option to discover the source files, and
	         updates the ^TORIGINS^t file appropriately.
	           ^Vsrcfiles^v         specifies the files exactly using brace expansion,
	           ^Vsrctoc^v           specifies the ^ITOC^i file which contains the file list.
	           ^T--cflags-only-I^t  copies ^Uinclude^u^T/^t^Upkg^u^T.^t^O[^och^O]^o.
	       ^T$PGM^t ^[^UOPTIONS^u^] ^Tupdate^t
	         Updates local copies whose ^Iorigin^i files have changed.
	       ^T$PGM list^t
	         Lists packages present in ^O$^o^TPKG_CONFIG_PATH^t paths.
	       ^T$PGM cmds^t
	         Lists sub-commands.
	===SPARKLE===
	help-usage
} # }}}
# process -options {{{1
export VERBOSE=false
export CD_TO_PATH=
while getopts ':vC:h' Option; do
	case $Option in
		v)	export VERBOSE=true;											;;
		C)	CD_TO_PATH=$OPTARG;												;;
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
function subcmd-to-cmd { # {{{1
	local c
	for c in subcmd-"$1"{,.ksh}; do
		REPLY=$(whence "$c") || continue
		[[ -n $REPLY ]]&& break
	done
	[[ -n $REPLY ]]|| die "Unknown sub-cmd ^T$1^t."
} # }}}1
function subcmd-help { # {{{1
	(($#))|| usage
	subcmd-to-cmd "$1"
	case $REPLY in
		help)	help-usage;		;;
		*.ksh)	"$REPLY" -h;	;;
		*)		f-help "$1";	;;
	esac
} #}}}1

needs use-app-paths needs-cd
use-app-paths outsrc

subcmd-to-cmd "$1"
shift
cmd=$REPLY

[[ -n ${CD_TO_PATH:-} ]]&& {
	CD_TO_PATH=$(realpath "${CD_TO_PATH:-.}" 2>&1) ||
		die "${CD_TO_PATH#realpath: }"
	needs-cd -or-die "$CD_TO_PATH"
  }

$VERBOSE && prn-cmd $cmd "$@"
$cmd "$@"; exit

# Copyright (C) 2024 by Tom Davis <tom@greyshirt.net>.
