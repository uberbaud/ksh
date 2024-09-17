#!/bin/ksh
# <@(#)tag:tw.lucas.uberbaud.foo,2024-09-10,23.03.58z/4f47f7c>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Toggle mouse state with ^Txinput^t
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
function is-mouse-enabled { # {{{1
	set -- $(
		xinput list-props /dev/wsmouse |
			awk -F: '/^	Device Enabled/ {print $2}'
	)
	[[ $1 == [01] ]]||
		die "Device Enabled is: ^T$1^t (expected ^B0^b or ^B1^b)"
	(($1))
} # }}}
function park-mouse { # {{{1
	local IFS=x
	set -- $(xrandr | awk '/\*/ {print $1;nextfile}')
	xdotool mousemove ${1:-0} ${2:-0}
} # }}}1
(($#))&& usage;

needs awk xdotool xinput xrandr

if is-mouse-enabled; then
	do_thing=disable
else
	do_thing=enable
fi

for d in /dev/wsmouse{,0,1}; do
	xinput $do_thing $d
done
[[ $do_thing != enable ]]&& park-mouse

# Copyright (C) 2024 by Tom Davis <tom@greyshirt.net>.
