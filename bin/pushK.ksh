#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-08-09:tw/02.36.22z/54749b1>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t
	         Save ^Bksh^b config to ^Bgithub.com^b.
	       ^T${PGM} -h^t
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
function warnOrDie { #{{{1
	case $warnOrDie in
		die)  die "$@" 'Use [1m-f22m to force an edit.';		;;
		warn) warn "$@";											;;
		*)    die '[1mProgrammer error[22m:' \
					'warnOrDie is [1m${warnOrDie}[22m.';		;;
	esac
} # }}}1
(($#))&& die 'Unexpected arguments. Expected ^Bnone^b.'

i-can-haz-inet	|| die 'No internet' "$REPLY"
cd ${KDOTDIR:?}	|| die 'Could not ^Tcd^t to ^S$KDOTDIR^s.'

bin/update-help-completions.ksh

alias FAIL='{ warn "FAILED"; exit 1; }'

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
[[ $branch == master ]]|| {
	changed=false

	# update the index
	git update-index -q --ignore-submodules --refresh

	# add untracked and unignored files, if any
	set -A untracked -- $(git ls-files --exclude-standard --others)
	[[ -n ${untracked[0]:-} ]]&& {
		warn "Adding ${untracked[@]}"
		git add "${untracked[@]}" || FAIL
	  }

	# check for unstaged changes in the working tree
	git diff-files --quiet --ignore-submodules -- || {
		warn "Unstaged changes."
		git diff-files --name-status -r --ignore-submodules -- |
			sed 's/^/        /' >&2
		warn 'Staging changes'
		git add --all || FAIL
	  }

	# check for uncommitted changes in the index
	git diff-index --cached --quiet HEAD --ignore-submodules -- || {
		warn "Uncommitted changes"
		git diff-index --cached --name-status -r --ignore-submodules HEAD |
			sed 's/^/        /' >&2
		warn 'Committing'
		git commit -av || FAIL
	  }
  }

git checkout master		|| die '^Bcheckout master^b'
git merge $HOST			|| die "^Bmerge $HOST^b"
git push				|| die '^Bpush^b'
git checkout $HOST		|| die "^Bcheckout $HOST^b"

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
