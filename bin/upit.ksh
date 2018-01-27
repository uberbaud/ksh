#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-11-07:tw/19.07.07z/2de0306>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

new-array name dotf exec cmds haz

function @ { # {{{1
	local NAME="$1 ($3)" DOTF="$2" EXEC="$3"; shift 3
	+name "$NAME"
	+dotf "$DOTF"
	+exec "$EXEC"
	+cmds "$*"
	/usr/bin/which "$EXEC" >/dev/null 2>&1 || return
	+haz "$NAME"
} # }}}1
#   name          dotf          exec      SUBCOMMANDS (cmds)
@   Git           .git          git       pull
@   Git+Modules   .gitmodules   git       pull submodule update --remote
@   Fossil        .fslckout     fossil    pull co --latest
@   Subversion    .svn          svn       update
@   Mercurial     .hg           hg        pull update
@   Bazaar        .bzr          bzr       update
@   Darcs         .darcs        darcs     update
@   RsyncUp       .rsyncup      rsyncup   fetch

# Usage {{{1
NL='
' # <- a newline
this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	supported="$(printf '%s\n' "${haz[@]}"|sort|column -c 68)"
	gsub "$NL" "$NL             ^B" "$supported"
	gsub ' (' '^b (^T' "$REPLY"
	gsub ')' '^t)^B' "$REPLY"
	supported="^B$REPLY^b"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Calls the appropriate ^BVersion Control Software^b (vcs).
	         Supported and installed ^Ivcs^i systems:
	             $supported
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
(($#))&& die 'Too many arguments. Exepected ^Bnone^b.'

name-is-empty && die 'Impossibly, ^S$name^s is empty.'
found=false
integer i=${#name[*]}
while ((i--)); do
	[[ -a ${dotf[i]} ]]|| continue
	found=true

	EXEC="${exec[i]}"
	which $EXEC >/dev/null 2>&1 || {
		warn "Found ^B${dotf[i]}^b, but ${name[i]} is not installed."
		continue
	  }

	"$EXEC" ${cmds[i]}
	break
done

$found || die 'This is not a supported ^Ivcs^i repository.'

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
