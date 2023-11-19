#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2023-11-08,16.20.08z/1aa11a3>

# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^Torchestrate^t ^Uscore^u
	         Extract and expand macro code snippets into source code files.
	       ^T$PGM^t ^Ttranspose^t ^[^T-t^t ^Utype^u^] ^Uscore^u ^[^Uoutfile^u^]
	         Transform ^Uscore^u into ^Uoutfile^u.
	       ^T$PGM help^t ^Usub-cmd^u
	         Show help for ^Usub-cmd^u.
	       ^T$PGM help^t^|^T-h^t
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
function validate-subcmd { # {{{1
	[[ $1 == @(orchestrate|transpose|help) ]]||
		die "Unrecognized ^Bsub-command^b ^V$1^v" "Expected one of $s_cmdlst."
} # }}}1
function help { # {{{1
	(($#))|| usage
	[[ $1 == help ]]&& {
		sparkle <<-===SPARKLE===
		^F{4}Usage^f: ^Tensemble help^t ^Usub-cmd^u
		         Show extended help for ^Usub-cmd^u.
		===SPARKLE===
		return
	  }
	validate-subcmd "$1"
	"$1" -h
} # }}}1

needs use-app-paths
use-app-paths ensemble

needs orchestrate transpose

s_cmdlst='^Torchestrate^t, ^Ttranspose^t, or ^Thelp^t'
(($#))|| die "Missing required ^Bsub-command^b: $s_cmdlst."

validate-subcmd "$1"

"$@"; exit

# Copyright (C) 2023 by Tom Davis <tom@greyshirt.net>.
