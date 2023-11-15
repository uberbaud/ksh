#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2023-11-15,03.28.42z/34c9e97>

# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^Uvms^u ^Uvms-test-cmd^u
	         Create all new F/^Vvms^v^T-^t^O*^o functions
	         Uses  ^Uvms vms-test-cmd^u to determine if a given directory is
	           part of a ^Uvms^u repository. Any output will be discarded, only
	           the return code is used.
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
function write-has-fn { # {{{1
	local vms
	vms=${1#has-}
	cat <<-===
		# $(mk-stemma-header)
		# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab
		
		#: FUNCTION
		#:   vmgr test for repository type
		
		function $1 {
			whence -p $vms && (builtin cd "\${1:-.}" && $vms $TEST_CMD)
		} 1>/dev/null 2>&1

		# Copyright © $(date +'%Y') by Tom Davis <tom@greyshirt.net>.
	===
} # }}}1
function write-vms-fn { # {{{1
	cat <<-===
		# $(mk-stemma-header)
		# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab
		
		#: FUNCTION
		#:   vmgr vms-cmd
		
		function $1 {
			NOT-IMPLEMENTED
		}

		# Copyright © $(date +'%Y') by Tom Davis <tom@greyshirt.net>.
	===
} # }}}1
function write-fn { # {{{1
	fn=${1:?}
	fn_type=${2:?}
	p=$pathF/$fn
	if [[ -f $p ]]; then
		warn "^B$fn^b already exists. Not overwriting."
	else
		write-$fn_type-fn "$fn" >$p
	fi
} # }}}1
function main { # {{{1
	local subcmd fn p sponge
	for subcmd in $(<$fVMS_LIST); do
		write-fn $vms-$subcmd vms
	done
	write-fn has-$vms has
} #}}}1

(($#))||	die 'Missing required parameters: ^Uvms^u and ^Uvms-test-cmd^u.'
(($#<2))&&	die 'Missing required parameter: ^Uvms-test-cmd^u.'
(($#>2))&&	die 'Too many parameters. Expected only one (1): ^Uvms^u.'
vms=${1:-Weirdly, \$1 fails as empty.}
TEST_CMD=$2

needs needs-file needs-path "$vms"
self=$(realpath $0) || die "Could not ^Trealpath^t ^B$0^b"
app_path=${self%/*}; app_path=${app_path%/*}
vmsList=VMS-CMD-list
fVMS_LIST=$app_path/notes/$vmsList
pathF=$app_path/F

needs-file -or-die "$fVMS_LIST"
needs-path -or-die "$pathF"

main; exit

# Copyright (C) 2023 by Tom Davis <tom@greyshirt.net>.
