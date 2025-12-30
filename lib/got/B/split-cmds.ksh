#!/bin/ksh

set -o nounset

desparkle "${0##*/}" PGM
function usage { # {{{1
	sparkle <<-===
		^NUsage^n^G:^g
		    ^B$PGM^b
		        Creates help files for each of ^Bgot^b's commands made 
		        from ^Tman got^t's output.
		    ^B$PGM^b ^S...^s
		        Shows this help.
	===
} # }}}1
function mk-sparkled { # {{{1
	local word b e
	REPLY=^B$1^b
	shift
	for word; do
		e=; [[ $word == *\] ]]&& { e=^]; word=${word%\]}; }
		b=; [[ $word == \[* ]]&& { b=^[; word=${word#\[}; }
		case $word in
			...)	word=^S…^s;				;;
			-*)		word=^T$word^t;			;;
			\|)		word=^\|;				;;
			*)		word=^U$word^u;			;;
		esac
		REPLY=${REPLY:+$REPLY $b$word$e}
	done
} # }}}1
function new-cmd { # {{{1
	local cmd
	cmd=${1%% *}
	notify "$cmd";
	exec 3>got-$cmd
	print -ru3 -- "^Bgot $cmd^b"
	print -ru3
	mk-sparkled $1;
	print -ru3 -- "    $REPLY";
} # }}}1
function main { # {{{1
	local cmd
	exec 3>/dev/null

	while IFS= read ln; do
		if [[ $ln == [a-z]* ]]; then
			cmd=$ln
			[[ $cmd == *\[+([!\]]) ]]&& {
				read ln
				cmd="$cmd $ln"
			  }
			new-cmd "$cmd"
		else
			print -ru3 -- "    $ln"
		fi
	done

	exec 3>&-
}

AWK_PGM=$(</dev/stdin) <<-\
	===AWK===
		/The commands for got are as follows/ {p=1;next}
		/^   [^[:space:]]/ {nextfile}
		p {print substr(\$0,6)}
	===AWK===

if (($#)); then
	usage
else
	export SPARKLE_FORCE_COLOR=1
	needs-cd -or-die "${KDOTDIR:?}"/share/HS
	man width=84 got | col -b | unexpand |
		awk "$AWK_PGM" | main
fi; exit
