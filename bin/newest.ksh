#!/usr/bin/env ksh
# @(#)[:LP(&b}Tf`i(wv!XLyFE;: 2017/07/28 05:13:49 tw@csongor]
# vim: filetype=sh tabstop=4 textwidth=72 noexpandtab nowrap

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle <<----
	^F{4}Usage^f: ^T${PGM}^t ^[^T-dflpsx^t^] ^[^Ucount^u^] ^[^Ufiles/directories^u^]
	         Show the newest files in directory(s).
	           ^T-a^t  Include ^Ball^b file system objects.
	           ^T-b^t  Include ^Bblock devices^b.
	           ^T-c^t  Include ^Bcharacter devices^b.
	           ^T-d^t  Include ^Bfiles^b.
	           ^T-f^t  Include ^Bdirectories^b.
	           ^T-l^t  Include ^Blinks^b.
	           ^T-p^t  Include ^Bpipes^b.
	           ^T-s^t  Include ^Bsockets^b.
	           ^T-x^t  Include ^Bexecutables^b.
	           ^T-q^t  don't show paths.
	           ^Upath^u defaults to ^B\$PWD^b.
	           ^Ucount^u defaults to ^B$defcount^b.
	           The default is only ^Bfiles^b.
	       ^T${PGM} -h^t
	         Show this help message.
	---
	exit 0
} # }}}
# process -options {{{1
function bad_programmer {	# {{{2
	die 'Programmer error:'	\
		"  No getopts action defined for [1m-$1[22m."
  };	# }}}2
set -A fstypes --
typeset -i count=1
typeset -- paths=true
typeset -- want_all=false want_dir=false want_lnk=false want_pip=false
typeset -- want_sck=false want_exe=false want_fil=false use_default=true
typeset -- want_chr=false want_blk=false
while getopts ':acbdflpsxqh' Option; do
	case $Option in
		a)	want_all=true; use_default=false;						;;
		b)	want_blk=true; use_default=false;						;;
		c)	want_chr=true; use_default=false;						;;
		d)	want_dir=true; use_default=false;						;;
		f)	want_fil=true; use_default=false;						;;
		l)	want_lnk=true; use_default=false;						;;
		p)	want_pip=true; use_default=false;						;;
		s)	want_sck=true; use_default=false;						;;
		x)	want_exe=true; use_default=false;						;;
		q)	paths=false;											;;
		h)	usage;													;;
		\?)	die "Invalid option: [1m-$OPTARG[22m.";				;;
		\:)	die "Option [1m-$OPTARG[22m requires an argument.";	;;
		*)	bad_programmer "$Option";								;;
	esac
done
# remove already processed arguments
shift $(($OPTIND - 1))
# ready to process non '-' prefixed arguments
# /options }}}1

if !(($#)); then
	set -- *
	[[ "$1" == '*' ]]&& die 'Directory is empty.'
elif (($#==1)); then
	[[ "$1" == '*' ]]&& die 'No files match criteria.'

	if [[ $1 != *[!0-9]* && ! -e $1 ]]; then
		count=$1
		shift
	elif [[ -d "$1" ]]; then
		set -- "$1"/*
		(($#==1)) && {
			[[ "$1" == '*' ]]&& die 'Directory is empty.'
		  }
	fi
else
	if [[ $1 != *[!0-9]* && ! -e $1 ]]; then
		count=$1
		shift
	else
		local maybe
		eval "maybe=\${$#}"
		[[ $maybe != *[!0-9]* && ! -e $maybe ]] && {
			count=$maybe
		  }
	fi
fi

local NL='
' # <- that's a single quote closing the quote around the newline (\n)
function getAll {
	stat -f '%m %N' "$@"			|
		sort -nr					|
		head -n $count				|
		sed -E -e 's/^[0-9]+ //'
}
# wrap script guts in a function so edits to this script file don't 
# affect running instances of the script.
function X { # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$want_all && {
	getAll "$@"
	return 0
}

$use_default && want_fil=true

# links are special because they are files too
local fsos
$want_lnk || {
	for f { [[ -h "$f" ]]|| set -A fsos -- "${fsos[@]}" "$f"; }
	set -- "${fsos[@]}"
	(($#))|| { warn 'No non-links found'; return 0; }
  }

unset fstypes
local fstypes
$want_fil && set -A fstypes -- "${fstypes[@]}" -f
$want_dir && set -A fstypes -- "${fstypes[@]}" -d
$want_lnk && set -A fstypes -- "${fstypes[@]}" -h
$want_exe && set -A fstypes -- "${fstypes[@]}" -x
$want_pip && set -A fstypes -- "${fstypes[@]}" -p
$want_sck && set -A fstypes -- "${fstypes[@]}" -S
$want_chr && set -A fstypes -- "${fstypes[@]}" -c
$want_blk && set -A fstypes -- "${fstypes[@]}" -b

set -A fsos
for f; do
	for t in "${fstypes[@]}"; do
		[ $t "$f" ]&& { set -A fsos -- "${fsos[@]}" "$f"; continue; }
	done
done

((${#fsos}))|| die 'No files match criteria.'
stat -f '%m %N' "${fsos[@]}"		|
		sort -nr					|
		head -n $count				|
		sed -E -e 's/^[0-9]+ //'

}; X "$@" # run the script  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Copyright (C) setEnv YEAR} by Tom Davis <tom@greyshirt.net>.
