#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2021-07-25,19.31.02z/5a3cd04>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

needs needs-path

P=${XDG_DATA_HOME:?}/gnu-tools

# PROCESS OPTIONS # {{{1
VERBOSE=true
SKIP_RESHELL=false
while [[ ${1:-} == -* ]]; do
	case $1 in
		-q) VERBOSE=false;					;;
		-n) SKIP_RESHELL=true;				;;
		-h)	set -- HELP;					;;
		*)  die "Unknown flag: ^B$1^b.";	;;
	esac
	shift
done
# }}}1
# USAGE {{{1
this_pgm=${0##*/}
(($#))&& {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle-path "$P"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-q^t^]
	         Create links for g{diff,deff3,make,sdiff} in $REPLY, and
	         Start a new shell with $REPLY prepended to ^O\$^o^VPATH^v.
	           so that, for instance, ^Tmake^t runs ^Tgmake^t.
	           ^T-q^t  Don\'t print header message.
	           ^T-n^t  Don\'t start a new shell.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 1
} # }}}1
function show-message { # {{{1
	local INFO WARN NORM

	if [[ -t 2 ]]; then
		INFO='\033[36m'
		WARN='\033[1;33m'
		NORM='\033[0m'
	else
		INFO=''
		WARN=''
		NORM=''
	fi

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

} # }}}1
function make-gnu-links { # {{{1
	needs-path -create -or-die "$P"
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
	((founds))
} # }}}1
function reshell_with_the_goods { # {{{1
	S=$(getent passwd $(id -u)|awk -F: '{print $7}')

	getent shells "$S" >/dev/null || {
		printf "$WARN%s$NORM" 'Could not get a valid shell.'
		return 1
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
	PS1=$ps1 ENV= PATH=$P:$PATH exec $S
} # }}}1

$VERBOSE		&& show-message
make-gnu-links	|| die "Did not link any of the GNU tools." "quitting"
$SKIP_RESHELL	|| reshell_with_the_goods

# Copyright (C) 2021 by Tom Davis <tom@greyshirt.net>.
