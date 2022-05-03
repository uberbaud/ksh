#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2022-05-02,22.56.06z/38d157f>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^Tmv^t^|^Tcp^t^] …
	         Wrapper to do to the RCS repository file what we're doing to the
	         checked out file.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
function -R-not-implemented { # {{{1
	desparkle "$this_pgm"
	die "^T-R^t is not implemented for ^T$REPLY ^B$CMD^b^t."
} # }}}1
function err-path { # {{{
	sparkle-path "${1:?}"
	gsub %% "$REPLY" "${2:?}"
	die "$REPLY"
} # }}}
function err-opts { # {{{1
	die 'Missing required arguments ^Tsource^t and ^Tdestination^t.'
} # }}}1
function get-cmd { # {{{1
	[[ -n ${1:-} ]]|| die 'Missing required argument ^UCMD^u.'
	[[ $1 == @(mv|cp) ]]|| die "Unsupported command ^B$1^b."
	CMD=$1; shift
} # }}}1
function get-flags { # {{{1
	typeset -i i=0
	while [[ ${1:-} == -* ]]; do
		[[ $1 == *R* || $1 == *a* ]]&& -R-not-implemented
		flags[i++]=$1
		shift
	done
	FLAG_COUNT=$i
} # }}}1
function get-source-files { # {{{1
	typeset -i s_errs=0
	typeset -i i=0
	while (($#>1)); do
		needs-file -or-warn "$1" || ((s_errs++))
		sources[i++]=$(readlink -fn "$1")
		shift
	done
	((s_errs!=1))&& ess=s
	((s_errs))&& die "Missing $s_errs source file${ess:-}."
	SRC_COUNT=$i
} # }}}1
function get-destinations { # {{{1
	local realpath
	if [[ -d $1 ]]; then
		# given destination is a directory
		realpath=$(readlink -fn "$1")/
	elif [[ -f $1 ]]; then
		# given destination is an existing file
		realpath=$(readlink -fn "$1")
	elif [[ $1 == */* ]]; then
		# given destination does not exist,
		# but could be a file with a path
		realpath=$(readlink -fn "${1%/*}")/${1##*/} ||
			err-path "${1%/*}" "Destination directory %% does not exist."
	else
		# given destination doesn't exist
		# but would have to be a file in the current directory,
		# we use readlink for consistency
		realpath=$(readlink -fn "$PWD")/$1
	fi
	DPATH=${realpath%/*}
	DFILE=${realpath##*/}

	[[ -d $DPATH ]]||
		err-path "$DPATH" "Destination directory %% does not exist."
	[[ ${#sources[*]} -gt 1 && -n $DFILE ]]&&
		die 'Multiple sources but destination is a file, not a directory.'
	DRCS=$DPATH/RCS
	needs-path -with-notice "$DRCS"
} # }}}1
function get-rcs-repo-and-dest { # {{{1
	local reponame
	reponame=${1##*/},v
	RCS_SRC=${1%/*}/RCS/$reponame
	if [[ -n $DFILE ]]; then
		RCS_DEST=$DPATH/RCS/$DFILE,v
	else
		RCS_DEST=$DPATH/RCS/$reponame
	fi
} # }}}1
function do-one { # {{{1
	# source file ($1) has already been verified to exist
	# AND `realpath`ed in `get-source-files`
	get-rcs-repo-and-dest "$1" &&
		"$CMD" ${flags[*]:+"${flags[@]}"} "$RCS_SRC" "$RCS_DEST"
	"$CMD" ${flags[*]:+"${flags[@]}"} "$1" "$DPATH/$DFILE"
} # }}}1

needs needs-file needs-path sparkle-path

[[ -z $* || $* == -h ]]&& usage

get-cmd "$@";			shift 1;			(($#))|| exec command $CMD
get-flags "$@";			shift $FLAG_COUNT;	(($#>=2))|| err-opts
get-source-files "$@";	shift $SRC_COUNT
get-destinations "$@";	# could shift 1, but we're done option processing

for s in "${sources[@]}"; do do-one "$s"; done; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
