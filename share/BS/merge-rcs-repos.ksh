#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2021-11-25,00.38.27z/363e098>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

BS=${KDOTDIR:?}/share/BS
TRAPSIGS='EXIT HUP INT QUIT TRAP BUS TERM'
NL='
' #←↑ capture newline
TAB='	'
DSCR=
MAINV=

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-t^t ^Udescription^u^] ^[^T-m^t ^Uhard copy^u^] ^Ua,v^u ^Ub,v^u
	         Take two or more (2+) rcs,v files and checkout all revisions,
	         sorting by date, and reassemble, testing to make sure that 
	         makes sense, then replace the originals with hard links to the new 
	         amalgamated repository.
	           ^T-t^t  Use ^Udescription^u instead of any description used in
	               the existing repository files.
	           ^T-m^t  Make a hard link to ^Uhard copy^u and soft links to all 
	               the existing repository files.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
while getopts ':m:t:h' Option; do
	case $Option in
		m)	MAINV=$OPTARG;													;;
		t)	DSCR=$OPTARG;													;;
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
function test-match { # {{{1
	local p f P C
	P=1.text
	for f in *.text; do
		C=${f#*-}
		[[ $C == $P ]]|| {
			print -- "\033[33m$p -> $f\033[39m"
			diff -u "$f" "$p"
			P=$C
		}
		p=$f
	done | less
	yes-or-no 'Are these all these histories of a single file'
} # }}}1
function normalize-descr-list { # {{{1
	local rm-trailing-tab rm-count-prefix
	rm_trailing_tab="s/$TAB\$//"		# put there by `tr \\n \\t`
	rm_count_prefix='s/^ +[0-9]+ //'	# remove `uniq -c` count
	sed -E -e "$rm_trailing_tab" -e "$rm_count_prefix"
} # }}}1
function list-descriptions { # {{{1
	local d
	for d in DESCRIPTION.*; do
		tr \\n \\t <$d
		print
	done | sort | uniq -c | sort -nr | normalize-descr-list
} # }}}1
function get-description { # {{{1
	local IFS Dscr
	IFS=$NL
	set -- $(list-descriptions) 
	if (($#)); then
		print -u2 -- "\033[33m Description for\033[39;1m$1\033[0m"
		select Dscr { yes-or-no "Description: \"$Dscr\"" && break; }
	else
		Dscr=$1
	fi
	print $Dscr
} # }}}1
function rcs-recompose-all { # {{{1
	local repoName fName t m
	repoName=$1
	fName=${1%,v}	# file of `co` result

	# Create an empty repo quietly and disable strict locking.
	rcs -q -i -U -t"-${DSCR:-"$(get-description "$fName")"}" "$fName"

	# incorporate all of the previous changes
	for t in *.text; do
		m="$(<${t%.text}.msg)"
		ln -f "$t" "$fName"
		ci -q -j -m"${m:-[not specified]}" "$fName"
	done
	rcs -L "$fName" # enable strict locking, previously disabled
} # }}}1
function verify-repos { # {{{1
	local n v r i repo_names
	set -A repo_names -- "${1##*/}"
	i=0

	for v; do
		# verify that each name names a file that is an RCS repository.
		[[ -f $v ]]|| die "^B$v^b is not a file."
		f=$(rlog -R $v 2>/dev/null) ||
			die "^B$v^b is not an ^SRCS^s file."
		[[ $f == $v ]]||
			die "^B$v^b is not an ^SRCS^s file." "^B$f^b is the repository."

		# get unique repository names
		n="${v##*/}"
		for r in "${repo_names[@]}"; do
			[[ $n == $r ]]&& continue 2
		done
		repo_names[i++]=$n
	done

	[[ ${#repo_names[*]} -gt 1 ]]&&
		die 'There are multiple repo names:' "${repo_names[@]}"

	REPLY=${repo_names[0]}
} # }}}1
function CleanUp { # {{{1
	cd ~
	rm -rf "$dTMP"
} # }}}1
function cleanUp { rm -rf "${dTMP:?}"; }
function main { # {{{1
	local i
	i=1; for v { rcs-decompose "$v" $((i++)); }
	test-match || return
	rcs-recompose-all "$REPO_NAME"

	# we're good, but don't clean up working directory since we're
	# overwriting the originals. We'll cleanup if we exit cleanly.
	trap - $TRAPSIGS

	# overwrite old partial-repo,v with new combined,v, softlink if -m
	# was used.
	if [[ -n $MAINV ]]; then
		H=$MAINV/$REPO_NAME
		for v { ln -fs "$H" "$v"; }	# do soft links first, then
		ln -f "$H" "$REPO_NAME"		# possibly overwrite soft with hard
	else
		# make only hard links, all are equal
		for v { ln -f "$REPO_NAME" "$v"; }
	fi
} # }}}1

(($#<2))&& die 'Need at least two (2) files to merge.'

needs rlog co needs-path rcs-decompose

# ensure all the parameters are in fact rcs repository files, and that
# we only have a single repo name though in multiple directories.
verify-repos "$@"
REPO_NAME=$REPLY

# verify -m points to a possible file/directory
[[ -n $MAINV ]]&& {
	if [[ $MAINV == *,v ]]; then
		[[ $MAINV == */$REPO_NAME ]]||
			die "^T-m^t points to ^S${MAINV##*/}^s, not ^S$REPO_NAME^s."
		MAINV=${MAINV%/*}
	fi
	needs-path "$MAINV" ||
		die "^T-m^t path $REPLY does not exist and could not be created."
  }

# since we're going to change directories, lets get full paths
for r { full_paths[i++]=$(readlink -fn "$r"); }
MAINV=$(readlink -fn "$MAINV")

# set up temp folder and move there
dTMP=$(mktemp -d)	|| die 'Could not ^Tmktemp^t.'
notify "Using temp directory ^<^B${dTMP##*/}^b^>."
# trap cleanUp $TRAPSIGS
needs-cd -or-die $dTMP

main "${full_paths[@]}" && : cleanUp; exit

# Copyright (C) 2021 by Tom Davis <tom@greyshirt.net>.
