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
function main { #{{{1
	has-auth || get-auth || die "The ^Tssh-add^t thing was not successful."
	/usr/bin/ssh yt.lan ./show-gw1100.ksh >$fTEMP

	[[ -s $fTEMP ]]|| return

	$want_clear && clear-screen
	h3 'Inside Weather'
	print -r -- "$(<$fTEMP)"
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

needs /usr/bin/ssh{,-add} fold cursor-to-line-col add-exit-actions

fTEMP=$(mktemp) || die 'Could not ^Tmktemp^t'
add-exit-actions "rm $fTEMP"

main "$@"; exit


