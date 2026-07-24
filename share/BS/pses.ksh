#!/bin/ksh
# <@(#)tag:tw.lukas.uberbaud.foo,2025-12-16,14.32.30z/265e266>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: "${FPATH:?Run from within KSH}"

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Exactly ^Tps^t but allows multiple ^I^T-p^t ^Ipid^i^u arguments.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
function main { # {{{1
	local pids opts
	typeset -i p=0 o=0
	while (($#)); do
		if [[ $1 == -p ]]; then
			if [[ -z ${2:-} || $2 == -* ]]; then
				warn "^T-p^t flag is missing a ^Upid^u."
			elif [[ $2 != +([0-9]) ]]; then
				warn "^T-p^t arg is not an integer ^(^T$2^t^)."
			else
				pids[p++]=$2
				shift 2
			fi
		else
			opts[o++]=$1
			shift 1
		fi
	done
	set -- ${pids[*]:+"${pids[@]}"}
	(($#))|| die 'No ^Upid^us were passed.'
	ps ${opts[*]:+"${opts[@]}"} -p $1
	shift
	for pid; do
		ps ${opts[*]:+"${opts[@]}"} -p $pid | sed 1d
	done
} #}}}1

[[ ${1:-'-h'} == -h ]]&& usage;
main "$@"; exit

# Copyright (C) 2025 by Tom Davis <tom@greyshirt.net>.
