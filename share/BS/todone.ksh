#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2020-05-20,01.52.22z/975880>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^Umatch1^u ^[^S…^s ^UmatchN^u^]
	         Mark matching tasks in ^S./TODO^s as done.
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

(($#))|| die 'Missing required parameter ^Umatch^u.'

needs dialog

[[ -f TODO ]]|| die 'No ^STODO^s file.'
NL='
' # ^ capture the newline
Sep="$NL@ "
TODO="$(<TODO)"
TODO="${TODO#${Sep#$NL}}"
splitstr "$Sep" "$TODO" todo

TimeStamp="$(date -u +'%Y-%m-%d %H:%M:%S Z')"
DoneList=''

# wrap script guts in a function so edits to this script file don't 
# affect running instances of the script.
function filter-tasks {
	local i Task Head Body Match
	i=0
	while ((i<${#todo[*]})); do
		Task="${todo[i]}"
		Head="${Task%%$NL*}"
		Body="${Task#$Head$NL}"
		head[i]="$Head"
		body[i]="$Body"
		[[ $Head == *' DONE '* ]]|| {
			for Match; do
				[[ $Body == *$Match* ]]|| continue
				DoneList="$DoneList $i"
				break
			done
		  }
		((i++))
	done
}

function mark-as-done {
	local i=$1
	head[i]="${head[i]} DONE $TimeStamp"
}

function handle-donelist {
	local taskNum
	(($#))|| die 'No matching tasks.'
	(($# == 1)) && {
		mark-as-done $1
		return 0
	  }

	COLUMNS=$(tput columns)
	W=$((COLUMNS-4))
	for taskNum; do
		print -n -- '\033[1;1H'
		dialog								\
			--title "Task Completed?"		\
			--tab-correct					\
			--tab-len 4						\
			--trim							\
			--cr-wrap						\
			--yesno "${body[taskNum]}" 7 $W
		(($?))|| mark-as-done $taskNum
	done
	clear
}

function update-TODO-file {
	local Task i=0
	[[ -f RCS/TODO,v ]]&& co -q -l TODO
	while ((i<$1)); do
		print -- "@ ${head[i]}$NL${body[i]}"
		((i++))
	done >TODO
	if [[ -f RCS/TODO,v ]]; then
		ci -q -j -m'complete' -u TODO
	elif [[ -d RCS ]]; then
		ci -q -i -t-'Stuff that needs doing.' -u TODO
	fi
}

function main {
	filter-tasks "$@"
	handle-donelist $DoneList
	update-TODO-file ${#todo[*]}
}


main "$@"; exit

# Copyright (C) 2020 by Tom Davis <tom@greyshirt.net>.
