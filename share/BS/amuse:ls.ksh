#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2018-01-27:tw/05.14.51z/295ebcc>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

ltype='performer'

# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-a^t^|^T-s^t^] ^[^Upattern^u^]
	         List performers matching ^Upattern^u.
	         If no pattern is given, a random beggining letter is used.
	           ^T-a^t  Search for matching ^Balbum names^b instead of performer.
	           ^T-s^t  Search for matching ^Bsong names^b instead of performer.
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
while getopts ':ash' Option; do
	case $Option in
		a)	ltype='album';											;;
		s)	ltype='song';											;;
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

needs amuse:env SQL
amuse:env

if (($#)); then
	for P; do
		[[ $P == +([A-Za-z0-9 ]) ]]|| {
			warn "Bad filter ^U$P^u."; continue;
		  }
		where="${where:-} OR value LIKE '$P%'"
	done
	where=${where# OR }
else
	random -e 28
	R=$(printf "\x$(printf %x $((63+$?)))")
	if [[ $R == '@' ]]; then
		where="value < 'A'"
	elif [[ $R == '?' ]]; then
		where="lower(value) BETWEEN 'sm' AND 't'"
	elif [[ $R == 'S' ]]; then
		where="lower(value) BETWEEN 's' AND 'sm'"
	else
		where="value LIKE '$R%'"
	fi
fi

SQL_AUTODIE=true
SQL_VERBOSE=false
SQL "ATTACH '${AMUSE_DATA_HOME:?}/amuse.db3' AS amuse;"
SQL <<-\
	==SQL==
	SELECT DISTINCT value
	  FROM amuse.vtags
	 WHERE label = '$ltype'
	   AND ( $where )
	   ORDER BY lower(value)
	 ;
	==SQL==

(( $(set +u; print ${#sqlreply[*]}) ))|| die "No results WHERE $where;"

for r in "${sqlreply[@]}"; { print -- "$r"; } | column

# Copyright (C) 2018 by Tom Davis <tom@greyshirt.net>.
