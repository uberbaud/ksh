#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2021-10-31,21.52.39z/49e34eb>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Check every {BF}S file for function call and report if it's  not needs-ed
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
while getopts ':h' Option; do
	case $Option in
		h)	usage;															;;
		\?)	die "Invalid option: ^B-$OPTARG^b.";							;;
		\:)	die "Option ^B-$OPTARG^b requires an argument.";				;;
		*)	bad-programmer "No getopts action defined for ^T-$Option^t."	;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
function check-it { # {{{1
	local file func
	file=$1
	func=$2
	# save all occurrences of the $func for quicker reprocessing
	egrep "$reStart$func$reEnd" "$file" >$fTemp

	# if it isn't used in the file (fTemp is empty) that's all we need
	[[ -z $fTemp ]]|| return

	# if the function is needs-ed, that's all we need
	egrep -q "\\<needs\\>.*[[:space:]]+$func$reEnd" "$fTemp" && return

	# if the function is defined in the file, that's all we need
	egrep -q "\\<function[[:space:]]+$func[[:space:]]+{" "$fTemp" && return

	# otherwise, it's in the file, BUT it was neither defined nor
	# needs-ed
	print -r -- "${file#$KDOTDIR/share/}: $func"

	print "    >$fTemp"
	exit

} # }}}1

fTemp=$(mktemp) ||
	die 'Could not ^Tmktemp^t.'
#trap "rm '$fTemp'" EXIT

reShWordBoundary='[ \t;&\)\|]'
reStart="(^|$reShWordBoundary)"
reEnd='($reShWordBoundary|$)'

needs needs-cd
# wrap script guts in a function so edits to this script file don't 
# affect running instances of the script.
function main {
	needs-cd -or-die $KDOTDIR/share/FS
	set -- * # all the shared functions
	# loop over every function definition, script (FILE)
#	for s in $KDOTDIR/share/FS/* $KDOTDIR/share/BS/*; do
	for s in $KDOTDIR/share/BS/*; do
		# and for that file, check for each function
		for f; do
			print -nu2 -- "${s#/home/tw/config/ksh/share/}: $f\033[K\n\033[A"
			check-it "$s" "$f"
		done
	done
	print -u2
}

main "$@"; exit

# Copyright (C) 2021 by Tom Davis <tom@greyshirt.net>.
