#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-08-15:tw/20.20.19z/549db7>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t
	         Show a weather graph for Charlotte.
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
while getopts ':h' Option; do
	case $Option in
		h)	usage;													;;
		\?)	die "Invalid option: [1m-$OPTARG[22m.";				;;
		\:)	die "Option [1m-$OPTARG[22m requires an argument.";	;;
		*)	bad_programmer "$Option";								;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1

: ${DISPLAY:?}
needs curl display xrandr awk needs-path

integer edgeOffset=20
graph_url='http://forecast.weather.gov/meteograms/Plotter.php'

new-array opts
+opts lat='35.39'
+opts lon='-80.71'
+opts wfo='GSP'
+opts zcode='NCZ072'
+opts gset='18'
+opts gdiff='3'
+opts unit='0'
+opts tinfo='EY5'
+opts ahour='0'
+opts pcmd='11000111101110000000000000000000000000000000000000000000000'
+opts lg='en'
+opts indu='1!1!1!'
+opts dd=''
+opts bw=''
+opts hrspan='48'
+opts pqpfhr='6'
+opts psnwhr='6'

runPath=${XDG_DATA_HOME:?}/run/weather
needs-path -create -or-die "$runPath"
builtin cd $runPath ||
	die 'No such directory ^B$XDG_DATA_HOME/run/weather^b.'

splitstr x "$(xrandr|awk '/\*/ {print $1}')" geometry
((${#geometry[*]}==2))||			die 'Could not get screen geometry'
[[ ${geometry[0]} == *[!0-9]* ]]&&	die 'Could not get screen geometry'
[[ ${geometry[1]} == *[!0-9]* ]]&&	die 'Could not get screen geometry'

integer W=${geometry[0]}
integer H=${geometry[1]}
integer O=$edgeOffset

infoImg='downloading-chart.png'
[[ -f $infoImg ]]||
	warn "No such image file ^B$infoImg^b."

function get-img-w-h { identify -format "w=%[fx:w];h=%[fx:h]" "$1"; }

function doit {
	eval "$(get-img-w-h "$infoImg")"
	display -immutable -geometry ${w}x${h}+$((W-O-w))+$O $infoImg &
	infoPid=$!
	chart="chart-$(date -u +'%Y-%m-%d,%H:%M:%S'z)"
	graph_opts=''
	for o in "${opts[@]}"; { graph_opts="$graph_opts&$o"; }
	graph_opts=${graph_opts#&}
	curl -o "$chart" -sL "$graph_url?$graph_opts"
	eval "$(get-img-w-h "$chart")"
	kill $infoPid
	display -immutable -geometry ${w}x${h}+$((W-O-w))+$O "$chart" &&
		rm "$chart"
}

set +o nohup
doit >log 2>&1 &

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
