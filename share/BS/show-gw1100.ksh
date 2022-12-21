#!/bin/ksh

set -u; : ${FPATH:?No FPATH}

this_pgm=${0##*/}
function usage { #{{{1
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle <<-===SPARKLE===
	^NUsage^n: ^T$PGM^t ^[^T-c^t^]
	         Print latest weather station values.
	           ^T-c^t  Clear the screen before printing.
	       ^T$PGM^t ^T-h^t
	         Show this help message
	===SPARKLE===
	exit 0
} #}}}
function has-auth { # {{{1
	/usr/bin/ssh-add -l >/dev/null
} # }}}1
function get-auth { # {{{1
	notify "Gather passphrase"
	/usr/bin/ssh-add < /dev/null 2>&1 |
		fold -s -w 52
} # }}}1
function clear-screen { # {{{1
	print -n -- '\033[H\033[2J\033[3J\033[H\c'
} # }}}1
function do-local  { # {{{1
	local F
	needs use-app-paths
	use-app-paths gw1100
	F=${FPATH%%:*}

	(($#))|| set -- show-latest

	[[ -f $F/$1 ]]|| die "No gw1100 function ^B$1^b."
	whence -v $1 >/dev/null || die "^B$1^b is not a function"
	"$@"
} # }}}1
function do-remote { #{{{1
	local header fTEMP

	needs /usr/bin/ssh{,-add} fold cursor-to-line-col add-exit-actions

	fTEMP=$(mktemp) || die 'Could not ^Tmktemp^t'
	add-exit-actions "rm $fTEMP"

	set -A opt
	i=0; for o; do shquote "$o" "opt[$((i++))]"; done
	((i))|| opt[0]=

	/usr/bin/ssh yt.lan ". \$ENV; $this_pgm ${opt[*]}" >$fTEMP

	[[ -s $fTEMP ]]|| return

	$want_clear && clear-screen

	h3 "$(sed -n '$p')"
	sed -e '$d'
} # }}}1
function main { # {{{1
	if [[ $(hostname) == yt.lan ]]; then
		do-local "$@"
	else
		do-remote "$@"
	fi
} # }}}1

want_clear=false
while [[ ${1:-} == -* ]]; do
	case ${1#-} in
		c) want_clear=true;				;;
		h) usage;						;;
		*) die "Unknown flag ^B$1^b.";	;;
	esac
	shift
done

main "$@"; exit
