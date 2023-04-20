#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2019-11-26,03.54.13z/12e32a8>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

which=full
action=append

# Usage {{{1
typeset -- this_pgm=${0##*/}
desparkle "$this_pgm"
PGM=$REPLY
function usage {
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-r^t^|^T-l^t^] ^UsqlPattern^u
	         Show or edit list of songs matching ^%^UsqlPattern^u^%.
	           ^T-p^t  prepend to ^Ssong.lst^s (defaults to ^Sappend^s).
	           ^T-l^t  list, do not edit.
	           ^T-r^t  raw vtags output (implies ^T-l^t).
	         If no search term is given, the ^Icurrent^i song list is printed.
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
flag=
while getopts ':lprh' Option; do
	case $Option in
		l)	action=list; flag=l									;;
		p)	action=prepend; flag=p;								;;
		r)	which=raw; action=list; flag=r;						;;
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
function list-current-songlist { # {{{1
	if [[ -s song.lst ]]; then
		awk -F\\t '{print $2}' song.lst
	elif [[ $(<$AMUSE_RUN_DIR/random) == true ]]; then
		print '  ^Srandom^s' |sparkle >&2
	else
		print '  ^Gempty^g'  |sparkle >&2
	fi
} # }}}1
function show-raw { # {{{1
	SQL <<-==SQLITE==
	SELECT file, kind, label, value
	  FROM amuse.vtags
	 WHERE value LIKE $1
	     ;
	==SQLITE==
	sql-reply ''
} # }}}1
function show-full { # {{{1
	SQL <<-==SQLITE==
	SELECT
		id,
		coalesce(performer,'-')
			|| '|' ||
		coalesce(album,'-')
			|| '|' ||
		coalesce(track,'-')
			|| '|' ||
		coalesce(song,'-'),
		dtenths
	  FROM vsongs
	 WHERE id IN (
		 SELECT file
		  FROM amuse.vtags
		 WHERE value LIKE $1
		)
	 ORDER BY album, track, performer
		;
	==SQLITE==
	sql-reply ''
} # }}}1
function start-playing { # {{{1
	$KDOTDIR/share/BS/volume.ksh >/dev/null
	amuse:send-cmd play
} # }}}1
function do-sql { # {{{1
	for W; do
		W="%$W%"
		SQLify W
		show-$which "$W"
	done
} # }}}1

[[ $# -eq 0 && $action != append ]]&&
	die "Missing ^UsqlPattern^u, required for flag ^T-$flag^t."	\
		"Use ^T$PGM^t without args to list ^Bsonglist^b."

needs awk amuse:env needs-cd sql-reply
amuse:env
needs-cd -or-die "${AMUSE_RUN_DIR:?}"

# handle no arguments / no database lookup
(($#))|| { list-current-songlist; exit; }

SQL "ATTACH '${AMUSE_DATA_HOME:?}/amuse.db3' AS amuse;"

function main {
	if [[ $action == list ]]; then
		local filter
		[[ -t 1 ]]&& filter='| less -FLSwX'
		eval "do-sql \"\$@\" ${filter:-}"
	else
		local H tmpfile
		tmpfile=$(mktemp songlist.XXXXXXXXX)
		trap "rm -f '$tmpfile'" EXIT

		M='You may change the first word to'
		if [[ $action == prepend ]]; then
			H="PREPEND // $M APPEND or IGNORE"
		elif [[ $action == append ]]; then
			H="APPEND // $M PREPEND or IGNORE"
		else
			bad-programmer "action is ^S$action^s."
		fi
		print -r -- "# $H" >$tmpfile
		do-sql "$@" >>$tmpfile
		"${VISUAL:-${EDITOR:-vi}}" "$tmpfile"

		[[ -s $tmpfile ]]|| exit

		read commentchar action ignore <$tmpfile
		[[ $commentchar == \# ]]|| die 'Missing header.' 'Doing nothing.'
		typeset -l A=$action
		sed -i -E -e '/^#/d' "$tmpfile"
		[[ -s $tmpfile ]]|| exit
		case $A in
			append)
				cat "$tmpfile" >>song.lst
				;;
			prepend)
				cat song.lst >>$tmpfile
				mv "$tmpfile" song.lst
				;;
			ignore)
				exit 0
				;;
			*)	die "Unknown action: ^B$A^b."
				;;
		esac
		start-playing
	fi
}

main "$@"; exit
# Copyright (C) 2019 by Tom Davis <tom@greyshirt.net>.
