#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2019-11-19,01.59.10z/9481bf>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

PRESDEFAULT=${XDG_DOCUMENTS_DIR:?}/presentations
SRC=presentation.mdp
CSS=presentation.css
NL='
'
SEPARATOR='--+(-)'
desparkle "$SEPARATOR"
dSEPARATOR=$REPLY

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^Upresentation path^u^|^Upresentation file^u^]
	         Create html slides and sparkle notes from ^Upresentation file^u.

	         If ^Upresentation file^u is not given ^S$SRC^s is looked
	         for in ^Upresentation path^u or in ^S\$PWD^s.

	         ^BPRESENTATION FILE FORMAT^b
	           The ^Upresentation file^u is a single file with ^S/$dSEPARATOR/^s separated
	           slides.

	           Slides are written in ^Smarkdown^s with embedded notes.

	           Notes are lines which begin with a semi-colon (^;) and are written
	           in ^Ssparkle^s.

	           The first ^Islide^i is for meta-data and is skipped.
	           Likewise, any comment-only slides are skipped.

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
(($#>1))&& die 'Expected zero (0) or one (1) parameters.'

if [[ -z ${1:-} ]]; then
	PRESPATH=$PWD
elif [[ -f $1 ]]; then
	PRESPATH=$(readlink -fn $1)
	desparkle "$1"
	[[ -z $PRESPATH ]]&& die "^B$REPLY^b is not a valid link."
	SRC=${PRESPATH##*/}
	PRESPATH=${PRESPATH%$SRC}
elif [[ -d $1 ]]; then
	PRESPATH=$(readlink -fn "$1")
else
	desparkle "$1"
	die "^B$REPLY^b is not a file nor a path."
fi

[[ -a $PRESPATH/$CSS  ]]|| CSS=$PRESDEFAULT/$CSS

cd $PRESPATH || die "Could not ^Tcd^t to ^S$PRESPATH^s."

META_TO=
META_BY=
META_ON=
META_COPYRIGHT=
META_TITLE=
typeset -i -Z3 PAGE

# wrap script guts in a function so edits to this script file don't 
# affect running instances of the script.
function mkAndCleanDir {
	(($#))|| die '^WBad Programmer^w: no argument to ^SmkAndCleanDir^s.'
	[[ -n ${1:-} ]]||
		die '^WBad Programmer^w: empty argument to ^SmkAndCleanDir^s.'
	[[ $1 == */* ]]&&
		die '^WBad Programmer^w: Directory name contains ^/.'

	[[ -d $1 ]]|| {
		notify "Making ^S$1^s directory."
		mkdir $1
	  }

	notify "Cleaning ^S$1^s directory."
	rm -rf $1/*
}

function checkFile {
	: ${1:?No or empty arg to checkFile}
	[[ -a $1 ]]|| die "Could not find file ^S$1^s."
	[[ -f $1 ]]|| die "^S$1^s is not a file."
	[[ -r $1 ]]|| die "^S$1^s is not readable."
}

function format-date {
	local NOW HMS Y M D ON
	NOW=$(date +%s)
	HMS=$(date -r $NOW +%H%M.%S)
	Y=${1%%-*}
	ON=${1#$Y-}
	M=${ON%-*}
	D=${ON#*-}
	THEN=$(date -j +%s $Y$M$D$HMS)
	((NOW<=THEN))||
		warn 'Presentation Date is in the past.'
	REPLY=$(date -r $THEN +'%B %e, %Y')
}

function entify {
	gsub '&' '&amp;' "$1"
	gsub '<' '&lt;' "$REPLY"
	gsub '>' '&gt;' "$REPLY"
}

function process-header {
	local L line
	L=0
	while IFS= read -ru4 line; do
		((L++))
		[[ $line == %%\ * ]]&& continue
		[[ $line == --+(-) ]]&& break
		[[ $line == %[[:space:]]* ]]|| {
			desparkle "$line"
			warn "Syntax Error: Line ^B$L^b:" "^U$REPLY^u"
			continue
		  }
		line="${line##%+([[:space:]])}"
		case $line in
			to[[:space:]]*) META_TO=${line##to+([[:space:]])};	;;
			by[[:space:]]*) META_BY=${line##by+([[:space:]])};	;;
			on[[:space:]]*) META_ON=${line##on+([[:space:]])};	;;
			Copyright[[:space:]]*) META_COPYRIGHT=$line;			;;
			*)
				[[ -z $META_TITLE ]]||
					warn 'Multiple Titles in Header!'
				META_TITLE=$line
				;;
		esac
	done
}

function clean-meta {
	[[ -z $META_TITLE ]]&&	warn 'Missing Meta ^BTitle^b.'
	entify "$META_TITLE"; META_TITLE="$REPLY"

	[[ -z $META_TO ]]&&		warn 'Missing Meta ^BAudience^b.'
	entify "$META_TO"; META_TO="$REPLY"

	[[ -z $META_BY ]]&&		warn 'Missing Meta ^BAuthor^b.'
	entify "$META_BY"; META_BY="$REPLY"

	[[ -z $META_ON ]]&&		warn 'Missing Meta ^BPresentation Date^b.'
	format-date "$META_ON"
	entify "$REPLY"; META_ON="$REPLY"

	entify "$META_COPYRIGHT"; META_COPYRIGHT="$REPLY"

}

function split-file {
	PAGE=1
	exec 5>build/p$PAGE
	while IFS= read -ru4 line; do
		[[ $line == --+(-) ]]&& {
			((PAGE++))
			exec 5>&-
			exec 5>build/p$PAGE
			continue
		  }
		print -ru5 -- "$line"
	done
	exec 5>&-
}

function process-source {
	exec 4<"$SRC"
	process-header
	clean-meta
	split-file
	exec 4>&-
}

function main {
	checkFile $SRC
	checkFile $CSS

	mkAndCleanDir build
	mkAndCleanDir html
	mkAndCleanDir notes

	cp $CSS html/presentation.css

	notify 'Making ^SMarkdown^s pages.'
	#split -p "$SEPARATOR" $SRC build/p
	process-source "$SRC"

	notify 'Converting ^SMarkdown^s pages to html pieces.'
	set -- build/*
	integer -Z3 i=1
	for f; do
		sed -e '/^;/d' $f |
			cmark --to html --smart --validate-utf8 >build/$i.phtm
		egrep '^;' $f >notes/$i.txt
		i=$((i+1))
	done

	notify 'Creating templates.'

	# IF we have a copyright, THEN create a rights section
	[[ -n $META_COPYRIGHT ]]&& HTML_RIGHTS="$(</dev/stdin)" <<-\
	===
	  <meta name="copyright"
	    content="$META_COPYRIGHT"
	    >
	  <meta name="doc-rights" content="Copywritten Work">
	  <!-- LICENSE
	
	       Permission is granted to copy, distribute and/or modify this 
	       document under the terms of the GNU Free Documentation 
	       License, Version 1.1 or any later version published by the 
	       Free Software Foundation; with no Invariant Sections, with no 
	       Front-Cover Texts, and no Back-Cover Texts.  A copy of the 
	       license is available at the link (URL) in the content section 
	       of the following link tag with the name license, or at the GNU 
	       Foundation's Web site (http://www.gnu.org/licenses/fdl.txt)
	
	    -->
	===

	HTML_PREFACE="$(</dev/stdin)" <<-\
	===
	<!DOCTYPE html>
	<html lang="en">
	<head>
	  <meta charset="UTF-8">
	  <meta name="author" content="$META_BY">
	  ${HTML_RIGHTS:-}
	  <link
	    rel="stylesheet"
	    type="text/css"
	    media="screen"
	    href="presentation.css"
	    >
	  <title>uberbaud-presents</title>
	</head>
	<body>
	    <h1>$META_TITLE</h1>
	===

	HTML_SUFFIX="$(</dev/stdin)" <<-\
	===
	    <div id="info">$META_TO / $META_ON</div>
	</body>
	</html>
	===



	set -- build/*.phtm
	for f; do
		n=${f#build/}; n=${n%.phtm}
		h=html/$n.html
		notify "Creating ^S$h^s."
		n=${n##+(0)}
		exec 4>$h
		print -ru4 -- "$HTML_PREFACE"
	    print -ru4 -- "<div id=\"main\">"
		print -ru4 -- "$(<$f)"
		print -ru4 -- "    </div>"
		print -ru4 -- "    <div id=\"counter\">${n##+(0)}/$#</div>"
		print -ru4 -- "$HTML_SUFFIX"
		exec 4>&-
	done

}

main "$@"; exit

# Copyright (C) 2019 by Tom Davis <tom@greyshirt.net>.
