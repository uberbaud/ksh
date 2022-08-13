#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-08-08:tw/00.54.34z/37f053f>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

UPPER_LIMIT=20
# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t ^[^T-H^t^]
	         save a mail part to disk and try to open it.
	           ^T-H^t  Force type to ^Shtml^s.
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
forceHTML=false
while getopts ':hH' Option; do
	case $Option in
		H)	forceHTML=true;											;;
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
function tidy-repeat { # {{{1
	local i n
	# HTML Tidy // tidy-html5 5.7.24
	# tidy's output is dependent on input features such as DOCTYPE and
	# the html namespace declarations, so we repeat the process until
	# the output is consistent.
	i=0
	while ((i<$UPPER_LIMIT)); do
		n=$((i+1))
		tidy -config ${MMH:?}/tidy.cfg --error-file $n.err $i.html > $n.html
		cmp -s $i.html $n.html && break
		((i++))
	done
	REPLY=$n
} # }}}1
function clean-html {( # {{{1
	local file tdir ferr fhtml
	file=$(realpath "${1:?}")
	tdir=$(mktemp -d)
	needs-cd -or-die $tdir
	ln "$file" 0.html	|| die "Could not ^Tln^t to ^S$file^s."
	tidy-repeat
	((REPLY))&& {
		fhtml=$REPLY.html
		print "$(<$fhtml)" >$file
		for ferr in *.err; do
			print -r -- "### $ferr ###"
			print -r -- "$(<$ferr)"
			print
		done >$file.err
	  }
	if ((REPLY < UPPER_LIMIT)); then
		rm *.{html,err}
		rmdir "$PWD"	|| die "Could not ^Trmdir^t ^S$PWD^s."
	else
		warn "^Ttidy^ ran ^B$REPLY^b times without standardizing"	\
			 "Did ^Enot^e ^Trmdir^t ^S$PWD^s"
	fi
)} # }}}1
needs tidy needs-cd needs-path

work=${XDG_PUBLICSHARE_DIR:?}/mail

needs-path -or-die "$work"
needs-cd -or-die "$work"
printf 'In \e[35m$XDG_CACHE_HOME/mail\e[39m\n'

new-array parts

mark=$(mktemp mark-XXXXXXXXX)

mhstore "$@"
for f in *; do
	[[ $f == $mark ]]&& continue	# skip mark
	[[ $f -ot $mark ]]&& continue	# skip old files
	if [[ $f == *.txt && $(file -bi "$f") == text/html ]]; then
		H=${f%.*}.html
		mv "$f" "$H" && f=$H
	elif [[ $f == *.html ]]; then
		:
	elif $forceHTML; then
		H=${f%.*}.html
		mv "$f" "$H" && f=$H
	fi
	# fix all the Microsoft (et al.) broken html marked as xhtml
	[[ $f == *.html ]]&& clean-html "$f"
	chmod a+r "$f"
	+parts "$f"
done
rm $mark

open "${parts[@]}"

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
