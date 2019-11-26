#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2018-01-27:tw/05.14.51z/295ebcc>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^Upattern^u^]
	         List performers, albums, songs filtered by given parameters.
	         If no pattern is given, a random letter is used.
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

needs amuse:get-workpath SQL

if (($#)); then
	for P; do
		[[ $P == +([A-Za-z0-9 ]) ]]|| {
			warn "Bad filter ^U$P^u."; continue;
		  }
		where="${where:-} OR value LIKE '$P%'"
	done
	where="${where# OR }"
else
	random -e 28
	R="$(printf "\x$(printf %x $((63+$?)))")"
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
amuse:get-workpath
SQL "ATTACH '$REPLY/amuse.db3' AS amuse;"
SQL <<-\
	==SQL==
	SELECT DISTINCT value
	  FROM amuse.vtags
	 WHERE label = 'performer'
	   AND ( $where )
	   ORDER BY lower(value)
	 ;
	==SQL==

(( $(set +u; print ${#sqlreply[*]}) ))|| die "No results WHERE $where;"

for r in "${sqlreply[@]}"; { print -- "$r"; } | column

# Copyright (C) 2018 by Tom Davis <tom@greyshirt.net>.
