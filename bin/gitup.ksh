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
	^F{4}Usage^f: ^T${PGM}^t ^Uupdate type^u
	         Where ^Uupdate type^u is one of ^Bsimple^b or ^Bmodules^b.
	         1. ^Tgit checkout master^t if not on master,
	         2. ^Tgit pull^t or ^Tgit submodule update --remote^t,
	         3. ^Tgit checkout^t ^Uprevious^u if needed, and finally
	         4. ^Tgit merge master^t.
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
function GIT { notify "git $*"; command git "$@"; }

i-can-haz-inet	|| die 'No internet' "$REPLY"

branch="$(command git rev-parse --abbrev-ref HEAD 2>/dev/null)"
[[ $branch == master ]]|| GIT checkout master

before="$(command git describe --always --dirty)"
[[ -f .gitmodules ]]&& GIT submodule update --remote
GIT pull || die "Couldn't ^Tpull^t."
after="$(command git describe --always --dirty)"

[[ $branch == master ]]|| {
	GIT checkout $branch
	[[ $before == "$after" ]]&& {
		warn 'Unchanged, quitting.'
		exit 1
	  }
	GIT merge master
  }

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
