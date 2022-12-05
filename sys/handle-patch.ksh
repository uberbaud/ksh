#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2018-03-21:tw/17.30.36z/53c3bf0>
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
	         Get and display information about an available syspatch.
	         Does not apply the patch. Use ^Tsyspatch^t for that.
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

needs w3m Xdialog
(($#))&& die 'Unexpected arguments. Wanted none.'

planBpath=/var/planB
[[ -a $planBpath ]]|| die "No such path ^B$planBpath^b."
[[ -d $planBpath ]]|| die "^B$planBpath^b is not a directory."
cd $planBpath >/dev/null 2>&1 || die "Could not ^Bcd^b to ^B$planBpath^b."

tmpD="$(mktemp -tdq hsyspatch.XXXXXXXXX)"
trap "rm -rf ${tmpD?Could not create a temporary directory.}" EXIT
[[ -d $tmpD ]]|| die 'Did not create temporary directory.'

errataH="https://www.openbsd.org/errata$(uname -r|tr -d .).html"
errataT="$tmpD/errata.txt"
errataN="$tmpD/errata.new"

w3m -no-graph "$errataH" >$errataT

announce=syspatch.announce
tempstore=syspatch.save
emptyfile=syspatch.new

[[ -s $announce ]]||	exit 0 # a change to nothing
[[ -a $tempstore ]]&&	die "Temporary file ^B$tempstore^b already exists."

[[ -a $emptyfile ]]&& die "^B$emptyfile^b already exists."
touch $emptyfile >/dev/null 2>&1 || die "Could not create ^B$emptyfile^b"
ln $announce $tempstore || die "Could not create ^B$tempstore^b."
mv $emptyfile $announce || die "Could not create ^B$announce^b."

set -- $(cat $tempstore)
(($#))|| die 'Did not get the patch names.'

rm $tempstore

i=0
for P { AWKPGM[i++]="/^ +\\* +${P%%_*}: /,/^\$/"; }

awk "${AWKPGM[*]}" "$errataT" >"$errataN"

new-array xdopts
+xdopts --backtitle 'SYSPATCH: Available Syspatchen'
+xdopts --ok-label 'Dismiss' --no-cancel
+xdopts --textbox "$errataN" $(($(wc -l <"$errataN")*3+5)) 180

trap - EXIT
(Xdialog "${xdopts[@]}"; rm -rf $tmpD)& >/dev/null 2>&1


# Copyright (C) 2018 by Tom Davis <tom@greyshirt.net>.
