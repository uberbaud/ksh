#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2021-08-29,01.15.26z/5b8153e>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

UB=/usr/local/bin
C=$(realpath $UB/clang-?? >/dev/null 2>&1)		&& export CC=$C
C=$(realpath $UB/clang++-?? >/dev/null 2>&1)	&& export CPP=$C
C=$(realpath $UB/clang++-?? >/dev/null 2>&1)	&& export CXX=$C
unset C UB

dBase=$HOME/src/textmunge/NeoVIM
dTSRepo=$dBase/nvim-treesitter
dTSRepoReadme=$dTSRepo/README.md
dTSParsers=$dBase/tree-sitter-parsers

github_treesitter='https://github.com/nvim-treesitter/nvim-treesitter.git'

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Gather supported parsers from ^Btree-sitter^b ^SREADME.md^s and either ^Tclone^t or
	         ^Tupdate^t and then, try to ^Tcompile^t.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
function bad_programmer {	# {{{2
	die 'Programmer error:'	\
		"  No getopts action defined for [1m-$1[22m."
  };	# }}}2
while getopts ':h' Option; do
	case $Option in
		h)	usage;												;;
		\?)	die "Invalid option: ^B-$OPTARG^b.";				;;
		\:)	die "Option ^B-$OPTARG^b requires an argument.";	;;
		*)	bad_programmer "$Option";							;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
function get-parser-urls { # {{{1
	local match prefix target suffix sed_cmd
	match='^- \[.\] \['			# lines like this are hopefully parsers
	target='https://[^\)]+'		# get the url
	egrep "$match" "$dTSRepoReadme" |egrep -o "$target"
} # }}}1
function update-repo { # {{{1
	notify "Updating ^S$1^s."
	command git -C "$1" reset --hard >/dev/null 2>&1
	command git -C "$1" pull
} # }}}1
function clone-repo { # {{{1
	NEW_REPOS=${NEW_REPOS:+"$NEW_REPOS" }$1
	notify "Cloning ^S$1^s."
	gg-clone "$2"
} # }}}1
function compile-repo { # {{{1
	needs-cd -or-die "$PWD/$1"
	tree-sitter generate
	tree-sitter test
} # }}}1
function update-or-clone { # {{{1
	local repo=$1 url=$2
	# we don't do anything except compile, so get rid of any changes
	if [[ -d $repo ]]; then
		update-repo "$repo"			|| return 1
	else
		clone-repo "$repo" "$url"	|| return 1
	fi
} # }}}1
function do-one { # {{{1
	local rname url
	url=$1
	rname=${url##*/}
	rname=${rname%.git}
	h2 "$rname"
	if update-or-clone "$rname" "$url"; then
		(compile-repo "$rname") || +errs_test "$rname"
	else
		+errs_repo "$rname"
	fi
} # }}}1
function list-em { # {{{1
	# column less margin width |tabs->spcs| add left margin
	  column -c $((COLUMNS-4)) |  expand  | sed -e 's/^/   /'
} # }}}1
function perrs { # {{{1
	had_errs=1
	h2 "$1"
	shift
	for r; do
		r=${r#tree-sitter-}
		r=${r%.git}
		print -r -- "$r"
	done | list-em
} # }}}1
function show-new-ts-parsers { # {{{1
	[[ -n ${NEW_REPOS:-} ]]|| return
	h2 "New language repos cloned"
	printf '%s\n' $NEW_REPOS | list-em
} # }}}1
function show-errs { # {{{1
	typeset -i had_errs=0
	show-new-ts-parsers
	errs_repo-not-empty && perrs "Could not update" "${errs_repo[@]}"
	errs_test-not-empty && perrs "Failed compile or test" "${errs_test[@]}"
	return $had_errs
} # }}}1

needs h3 new-array sed tree-sitter needs-cd needs-path
new-array errs_repo errs_test

eval "$(resize)"

[[ -d $dBase ]]|| die "No such directory ^S$dBase^s."
[[ -d $dTSRepo ]]|| {
	needs-cd -or-die "$dBase"
	command git clone "$github_treesitter" ||
		die "Could not clone ^Snvim-treesitter^s."
	[[ -d $dTSRepo ]]||
		die "cloned ^Snvim-treesitter^s directory does not exist."
	[[ -e $dTSRepoReadme ]]|| die "No such file ^S$dTSRepoReadme^s."
  }

needs-path -create -or-die "$dTSParsers"
needs-cd -or-die "$dTSParsers"

for url in $(get-parser-urls); do do-one "$url"; done; show-errs; exit

# Copyright (C) 2021 by Tom Davis <tom@greyshirt.net>.
