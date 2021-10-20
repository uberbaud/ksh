#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2021-07-25,19.31.02z/5a3cd04>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

needs needs-path

P=/home/tw/local/gnu-tools

QUIET=false
[[ ${1:-} == -q ]]&& {
	QUIET=true
	shift
  }

this_pgm="${0##*/}"
(($#))&& {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-q^t^]
	         Set an environment for running gnu dev tools as first class
	           for instance, make runs gmake
	           links g{diff,diff3,make,sdiff}
	           ^T-q^t  Don\'t print header message.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 1
}

S=$(getent passwd $(id -u)|awk -F: '{print $7}')

if [[ -t 2 ]]; then
	INFO='\033[36m'
	WARN='\033[1;33m'
	NORM='\033[0m'
else
	INFO=''
	WARN=''
	NORM=''
fi

$QUIET || {
	print -n -- "$INFO"
	cat >&2 <<-===
		# On OpenBSD, \`make\` is the bsd make, and GNU's make is a second class
		# citizen. In some cases (for instance where a subsidary make file is
		# called, \`make\` might fail because it expects the GNU make to be named
		# \`make\`.
		#
		# We can work around that by creating a softlink somewhere called
		# \`make\` which links to \`gmake\` and placing that first in our \$PATH
		#
		# THIS IS A QUICK AND DIRTY WORKAROUND.
		#
		# Obviously, the best thing would be to fix the subsidary makefile to
		# use a variable \$(MAKE) which can point to either name for GNU make.
		===
	print -- "$NORM"
  }

needs-path -or-die "$P"
typeset -i founds
for c in make {,s}diff diff3 {,e,f}grep; do
	g=$(whence -p g$c) || {
		warn "Could not find ^Tg$c^t." "skipping"
		continue
	  }
	[[ -e $P/$c ]]|| ln -s "$g" "$P/$c" || {
		warn "Could not ^Tln -s^t ^S$g^s."
		continue
	  }
	((founds++))
done
((founds))|| die "Did not link any of the GNU tools." "quitting"

getent shells "$S" >/dev/null || {
	printf "$WARN%s$NORM" 'Could not get a valid shell.'
	exit 1
  }

ESC=$(printf '\033')
W=$ESC[33m
N=$ESC[0m
I=$ESC[36m

cat <<-===
	$W
	Starting new shell ($I$S$W)
	$W  with $N$P
	$W  prefixed to $I\$PATH
	$W
	Use$N exit$W to exit
	$N
	===

ps1="\\[$ESC[4m\\]GNU Tools subshell ($S)\\[$ESC[24m\\]\\$ "
PS1="$ps1" ENV= PATH=$P:$PATH exec $S

# Copyright (C) 2021 by Tom Davis <tom@greyshirt.net>.
