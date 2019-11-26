#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2018-07-19:tw/04.55.44z/330193>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

period=6

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-dg^t^] ^[^T-m^t ^Umonths^u^]
	         Get recent weights and graph them
	           ^T-d^t  Dumps the data instead of graphing.
	           ^T-g^t  graph only (no entry).
	           ^T-m^t ^Umonths^u  Graphs last number of ^Umonths^u. Defaults to ^B$period^b.
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
WANT_ENTRY=true
DUMP_IT=false
while getopts ':dgm:h' Option; do
	case $Option in
		d)  DUMP_IT=true;										;;
		g)  WANT_ENTRY=false;									;;
		m)	period=$OPTARG;										;;
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

needs readkeys SQL

needs gnuplot

MAXLEN=5
MORNING=16
EVENING=30

function flash { tput flash; }
function screen-use-alt { tput smcup; }
function screen-restore-primary { tput rmcup; }
function goleft { tput cub1; }
function gohorz { print -n "\033[$1G"; }
function get-weight { # {{{1
	local col=$1 weight=$2 len=5
	[[ $name == readkeys ]]|| die "Unexpected process name ^B$name^b."
	gohorz $col
	print -n $weight
	while read -p class datum; do
		if [[ $class == c && $datum == [0-9] ]]; then
			if ((${#weight}==$MAXLEN)); then
				flash
			else
				weight="$weight$datum"
				print -n $datum
				((${#weight}==MAXLEN-2))&& {
					weight="$weight."
					print -n .
				  }
			fi
		elif [[ $class == [cfs] ]]; then
			case $datum in
				Enter)		REPLY="$weight"; return 0;	;;
				Tab)		REPLY="$weight"; return 0;	;;
				Escape)		REPLY="$weight"; return 1;	;;
				-)			REPLY="-";
							gohorz $col
							print -n "  -  "
							return 0
							;;
				h|Backspace)
							if ((${#weight})); then
								weight="${weight%?}"
								goleft 1
								print -n " "
								goleft 1
							else
								flash
							fi
							;;
				*)			flash
							;;
			esac
		elif [[ $class == q ]]; then
			print
			return
		else
			flash
		fi
	done
} # }}}1
function get-newday-vars { #{{{1
	SQL <<-==SQLITE==
	  SELECT date(day+1) FROM health.weight $LASTONE;
	  SELECT morning FROM health.weight WHERE morning IS NOT NULL $LASTONE;
	  SELECT evening FROM health.weight WHERE evening IS NOT NULL $LASTONE;
	==SQLITE==
	NEWDAY="${sqlreply[0]}"
	LASTMORNING="${sqlreply[1]}"
	LASTEVENING="${sqlreply[2]}"
} #}}}1
function save-info { # {{{1
	local d="$1" m="$2" e="$3"
	[[ $m == - ]]&& m=NULL
	[[ $e == - ]]&& e=NULL
	SQL <<-==SQLITE==
		INSERT INTO health.weight (day,morning,evening)
		  VALUES (julianday('$d'),$m,$e)
		  ;
	==SQLITE==
} # }}}1
function dump { #{{{1
	printf '%s\t%s\t%s\n' date mornings evenings
	integer i=0
	while ((i<${#sqlreply[*]})); do
		print -- "${sqlreply[i++]}"
	done
} #}}}1
function entry { # {{{1
	local m e
	SQL '.null -'
	gohorz $MORNING; goleft; print -n morning
	gohorz $EVENING; goleft; print -- evening
	readkeys |&
	read -p name pid
	while :; do
		get-newday-vars

		print -n -- "$NEWDAY"

		get-weight $MORNING ${LASTMORNING%?.?} || { tput el1; break; }
		[[ $REPLY != - ]]&& LASTMORNING="$REPLY"
		m=$REPLY

		get-weight $EVENING ${LASTEVENING%?.?} || { tput el1; break; }
		[[ $REPLY != - ]]&& LASTEVENING="$REPLY"
		e=$REPLY

		print
		save-info $NEWDAY $m $e
	done
	print
	kill -HUP $pid
} # }}}1
function graph { # {{{1
	SQL ".null ''"
	SQL <<-==SQLITE==
		SELECT julianday(MAX(day),'-$period months','start of month')
		  FROM health.weight
		     ;
		==SQLITE==
	SQL <<-==SQLITE==
		SELECT date(day), morning, evening
		  FROM health.weight
		 WHERE day >= ${sqlreply[0]}
		 ORDER BY day ASC
			 ;
		==SQLITE==

	$DUMP_IT && { dump; return 0; }

	datdir=$(mktemp -d)
	data="$datdir/plot.dat"
	trap "rm $data; rmdir $datdir" EXIT
	dump >$data
	print ${data:?}

	gnuplot <<----
		set terminal png
		set output '| display png:-'
		set timefmt '%Y-%m-%d'
		set xdata time
		set format x "%b %d"
		set ylabel "%b %d"
		set yrange [140:185]
		set grid
		plot "$data" skip 1 \
				using 1:2 title "mornings" with lines, \
			""	using 1:3 title "evenings" with lines
		---
} #}}}1
function main { #{{{1
	$WANT_ENTRY && entry
	graph
} # }}}1

DBNAME="${SYSDATA:?}/health.db3"
[[ -f $DBNAME ]]|| die 'No database ^B^S$SYSDATA^s/health.db3^b.'
TAB='	'
SQLSEP="$TAB"
SQL "ATTACH '$DBNAME' AS health;"
LASTONE='ORDER BY day DESC LIMIT 1'

main "$@"; exit

# Copyright (C) 2018 by Tom Davis <tom@greyshirt.net>.
