#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2020-12-10,01.51.06z/4d6cf66>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Checks the needs clause and adds links to [FB]S if needed
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
function warnOrDie { #{{{1
	case $warnOrDie in
		die)  die "$@" 'Use [1m-f22m to force an edit.';		;;
		warn) warn "$@";											;;
		*)    die '[1mProgrammer error[22m:' \
					'warnOrDie is [1m${warnOrDie}[22m.';		;;
	esac
} # }}}1
function try-path {
	warn "^Ttry-path^t: not yet implemented"
}
function try-script {
	warn "^Ttry-script^t: not yet implemented"
}
function try-function {
	[[ -f $FS/$1	]]|| return 1
	[[ -f F/$1		]]&& return 0
	ln -s $FS/$1 F/$1 ||
		warn "Could not link ^S\$FS/$1^s to ^S$2/F/^s."
}
function find-needs-for-host {
	find -f ./B ./F -type l -print0							|
		xargs -0 egrep -h '^[[:space:]]*needs[[:space:]]'	|
		egrep -o '[^[:space:]]+'							|
		sort -u
}
function provide-needs-for-host {
	local need host
	host=$1
	set -- $(find-needs-for-host)
	for need; do
#print "  $host: $need"
		try-function $need $host	||
			try-script $need $host		||
				try-path $need $host		||
					warn "Could not find ^B$need^b ($host)."
	done
}

function main {
	for h; do
		h=${h%/kshrc}
print "host: $h"
		needs-cd -or-warn "$h" || break
		provide-needs-for-host "$h"
		cd $KDOTDIR
	done
}

needs needs-cd

: ${KDOTDIR:?}
FS=$KDOTDIR/share/FS;	[[ -d $FS ]]|| die 'No directory ^S$K/share/FS^s.'
BS=$KDOTDIR/share/BS;	[[ -d $BS ]]|| die 'No directory ^S$K/share/BS^s.'

needs-cd -or-die "$KDOTDIR"
set -- */kshrc
main "$@"; exit

# Copyright (C) 2020 by Tom Davis <tom@greyshirt.net>.
