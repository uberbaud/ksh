#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-08-26:tw/19.43.42z/214fbf8>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

: ${FPATH:?Run from within KSH}
verses_to_read=7
verbose=false
readnext=true
translation='kjv'
# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-v^t^] ^[^T-r^t^] ^[^Umark^u^]
	         Show the NEXT chapter AFTER the one stored in ^S\$BIBLE_PATH^s^T/mark.^t^S\$mark^s.
	         ^T-v^t  verbose
	         ^T-r^t  reread most recently read passage.
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
while getopts ':rvh' Option; do
	case $Option in
		r)	readnext=false;											;;
		v)	verbose=true;											;;
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
function warnOrDie { #{{{1
	case $warnOrDie in
		die)  die "$@" 'Use [1m-f22m to force an edit.';		;;
		warn) warn "$@";											;;
		*)    die '[1mProgrammer error[22m:' \
					'warnOrDie is [1m${warnOrDie}[22m.';		;;
	esac
} # }}}1
function divy-mark { # {{{1
	local mark="$1" x='' cv='' b=''
	[[ $mark == *\) ]]&& {
		# there's a translation
		x="(${mark##*\(}"
		mark="${mark%%*( )"$x"}"
	  }
	cv="${mark##* }"
	b="${mark%%*( )"$cv"}"
	set -A reply -- "$b" "$cv"
	[[ -n $x ]]&& reply[2]="$x"
} # }}}1
function SQL { # {{{1
	local sql response; sql="$(cat)"
	set -A reply --
	$verbose && print -ru2 "$sql"
	print -rp "$sql"
	print -rp "SELECT '<ready>';"
	while :; do
		read -r -p response
		[[ $response == '<ready>' ]]&& break
		reply[${#reply[*]}]="$response"
		$verbose && print -ru2 "$response";
	done
} # }}}1
needs sqlite3

biblepath="${BIBLE_PATH:-${XDG_DATA_HOME:?}/bible}"
	[[ -d $biblepath ]]|| die 'Bad ^S$SBIBLE_PATH^s.'
cd "$biblepath" || die "Could not ^Tcd^t to ^B$biblepath^b."
	[[ -f bible.db ]]|| die 'No ^Sbible.db^s in ^S$BIBLE_PATH^s.'

needs ./bible.pl

sqlite3 -noheader -batch -list -separator '|' bible.db |&
trap "print -p '.quit'" EXIT
echo "SELECT NULL;" | SQL # empty the startup output

fmark="mark.${1:-daily}"
[[ -f $fmark ]]|| { # CREATE BOOKMARK } {{{1
	print "Mark 1:1-$verses_to_read ($translation)\n" >$fmark
	[[ -f $fmark ]]||
		die "^B$fmark^b doesn't exist and couldn't be created."
	$readnext = false;
  } # }}}1

$readnext && { # {{{1
	divy-mark "$(tail -n 1 "$fmark")"
	b="${reply[0]}"
	cv="${reply[1]}"
	c="${cv%%:*}"
	v2="${cv##*-}"
	x="${reply[2]:-"${translation:?}"}"; x="${x#\(}"; x="${x%\)}"

	SQL <<-=sqlite=
		SELECT	id
		  FROM	Text
		 WHERE	translation = '$x'
		   AND	book        = '$b'
		   AND	chapter     = $c
		   AND	verse       = $v2
		   ;
	=sqlite=
	[[ ${reply[0]} == +([0-9]) ]]|| die "Bad verse id: ${reply[*]}"
	t_id=${reply[0]}
	SQL <<-=sqlite=
		SELECT	book || ' '
				|| chapter || ':'
				|| min(verse) || '-' || max(verse)
				|| ' (' || translation || ')'
		  FROM (
			SELECT	*
			  FROM	Text
			 WHERE	translation = '${translation:?}'
			   AND	id > ${t_id:?}
			 ORDER BY booknum ASC, chapter ASC, verse ASC
			 LIMIT	${verses_to_read:?}
			 )
		GROUP BY book, chapter
		ORDER BY booknum
		;
	=sqlite=
	if ((${#reply[*]})); then
		printf '%s\n' "${reply[@]}" >"$fmark"
	else
		warn 'Starting over in Genesis.'
		printf "Genesis 1:1-$verses_to_read ($translation)\n" >"$fmark"
	fi
} # }}}1

[[ -s $fmark ]]|| die "^B$fmark^b is empty!"

set -A book_cv --
splitstr NL "$(cat <"$fmark")" marks
for mark in "${marks[@]}"; do
	divy-mark "$mark"
	set -A book_cv -- "${book_cv[@]}" "${reply[@]}"
done

exec ./bible.pl -c "${book_cv[@]}"

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
