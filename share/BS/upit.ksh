#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-11-07:tw/19.07.07z/2de0306>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

needs desparkle die h1 new-array notify splitstr warn

new-array name dotf exec cmds haz

B=$KDOTDIR/$HOST/B
GITUP=$B/gitup.ksh
[[ -x $GITUP ]]||
	die 'No ^S$B^s^T/gitup.ksh^t so using git pull.'

function @ { # {{{1
	local NAME="$1 (${3#"$B"/})" DOTF="$2" EXEC="$3"; shift 3
	+name "$NAME"
	+dotf "$DOTF"
	+exec "$EXEC"
	+cmds "$*"
	/usr/bin/which "$EXEC" >/dev/null 2>&1 || return
	+haz "$NAME"
} # }}}1
#   name          dotf          exec      SUBCOMMANDS (cmds)
@   Git           .git          $GITUP    simple
@   Git+Modules   .gitmodules   $GITUP    modules
@   Got           .got          $GITUP    simple
@   Git           HEAD          $GITUP    simple
@   Fossil        .fslckout     fossil    pull +AND+ co --latest
@   Subversion    .svn          svn       update
@   Mercurial     .hg           hg        pull update
@   Monotone      _MTN          mtn       pull +AND+ update
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
	^F{4}Usage^f: ^T$PGM^t ^[^T-v^t^] ^[^Udirectory^u ^U…^u^]
	         For each ^Udirectory^u given, ^Tcd^t to ^Udirectory^u and call the appropriate
	         ^BVersion Control Software^b (vcs). If none are given, uses ^S\$PWD^s.
	         If ^Udirectory^u includes the ^Idotfile^i, the parent directory is used.
	           ^T-v^t  Verbose.
	
	         Supported and installed ^Ivcs^i systems:
	             $supported
	       ^T$PGM -D^t
	         List ^Bdotfiles^b used to recognize the vcs.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
VERBOSE=false
function bad_programmer {	# {{{2
	die 'Programmer error:'	\
		"  No getopts action defined for [1m-$1[22m."
  };	# }}}2
while getopts ':Dvh' Option; do
	case $Option in
		v)	VERBOSE=true;											;;
		D)	printf "%s\n" "${dotf[@]}" |sort; return 0;				;;
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
(($#))|| set -- "$PWD"

name-is-empty && die 'Impossibly, ^S$name^s is empty.'

function set_re { # {{{1
	local IFS=\|
	re_dots="@(${dotf[*]})"
} #}}}1
function do-one {( # {{{1
	found=false
	[[ -a $1 ]]|| {
		desparkle "$1"
		die "^B$REPLY^b does not exist."
	  }

	eval "DIR=\"\${1%/$re_dots}\""
	desparkle "$DIR"
	dDIR="$REPLY"
	subst-pathvars "$DIR"
	h2 "upit $REPLY"
	$VERBOSE && notify "^Tcd^ting to ^B$dDIR^b."
	builtin cd "$DIR" || die "Could not ^Tcd^t to ^B$dDIR^b"

	integer i=${#name[*]}
	while ((i--)); do
		$VERBOSE && notify "Looking for ^B${dotf[i]}^b."
		[[ -a ${dotf[i]} ]]|| continue

		EXEC="${exec[i]}"
		which $EXEC >/dev/null 2>&1 || {
			warn "Found ^B${dotf[i]}^b, but ${name[i]} is not installed."
			continue
		  }

		$VERBOSE && notify "Found ^B${dotf[i]}^b."
		found=true

		splitstr ' +AND+ ' "${cmds[i]}"
		for CMD in "${reply[@]}"; do
			$VERBOSE && notify "Runing ^T$EXEC $CMD^t."
			"$EXEC" $CMD
		done
		break
	done

	$found || die "^B$dDIR^b is not a supported ^Ivcs^i repository."
)} # }}}1

integer RC=0
set_re
for d; do (do-one "$d"); ((RC+=$?)); done; exit $RC

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
