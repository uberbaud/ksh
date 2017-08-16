#!/bin/ksh
# @(#)[:16%1M8hieME7WR^W@!x<: 2017-08-15 02:33:43 Z tw@csongor]
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

: ${FPATH:?Run from within KSH}

wifi_config=${XDG_CONFIG_HOME:?}/wifi

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t ^[^Unwid^u^]
	         Connect to a wifi base station, perhaps the world.
	           The ^Unwid^u is the name of the base station.
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
shift $(($OPTIND - 1))
# ready to process non '-' prefixed arguments
# /options }}}1

# LOG-INET-STATS ←→ DELETE THIS {{{1
LOG_INET_STATS_RUNS=0
LOG_INET_STATS_awkpgm="$(cat)" <<-\
	\==AWK==
		BEGIN			{ FS=":" }
		/^[^\t]/		{ d=$1; next }
		d ~ /^lo/		{ next }
		/^\tinet6? /	{ print "\t"d":"$0 }
	==AWK==
function LOG-INET-STATS {
	local wh=AFTER
	((LOG_INET_STATS_RUNS++))|| {
		date -u +'[%Y-%m-%d %H:%M:%S %Z]'
		wh=BEFORE
	  }
	print "\t=== $wh ==="
	route -n get default 2>&1	|sed -e 's/^/	/'
	sysctl net.inet				|sed -e 's/^/	/'
	ifconfig -a					|awk "$LOG_INET_STATS_awkpgm"
} >>$HOME/log/i-can-haz-inet-stats
# DELETE TO HERE }}}1

[[ -d $wifi_config ]]|| die 'wifi config directory does not exist.'
needs doas ifconfig dhclient awk

(($#))||	die 'scanning is not yet implemented.'
(($#>1))&&	die 'Too many arguments. Expected at most one (1).'

LOG-INET-STATS # ← DELETE THIS

set -A cfgs -- $wifi_config/[0-9][0-9],$1*
((${#cfgs[@]}))|| die 'Could not find a matching wifi configuration file.'
((${#cfgs[@]}>1))&& { set -A cfgs -- "$(omenu "${cfgs[@]}")" || exit 0; }
nwid="${cfgs[0]#$wifi_config/[0-9][0-9],}"
gsub '
' ' ' "$(sed -e '/^[[:space:]]*;/d' -e '/^[[:space:]]*$/d' "${cfgs[0]}")"
eval "set -A wifiopts -- $REPLY"

awkpgm="$(cat)" <<-\
	\==AWK==
		/^[^ \t]/ {d=$1}
		/^\tmedia: IEEE802.11/ {print d}
	==AWK==

set -A wifi -- $(ifconfig -a|awk -F: "$awkpgm")

((${#wifi[*]}))||	die 'Could not find a ^Bwifi^b device.'
((${#wifi[*]}>1))&&	die 'Multiple ^Bwifi^b devices found. Bailing.'

# Three strikes and you're out.
# Requires *persist* attribute in /etc/doas.conf
doas true || doas true || doas true || die 'Needs rootness'
doas ifconfig $wifi down
for prop in bssid chan inet inet6 mode nwid nwkey wpa wpakey; do
	doas ifconfig $wifi -$prop
done

# set it up
desparkle "$nwid"
notify "Connecting to ^B$REPLY^b."
doas ifconfig $wifi nwid "$nwid" "${wifiopts[@]}"
doas ifconfig $wifi up
notify 'Getting an address.'
doas dhclient $wifi

LOG-INET-STATS # ← DELETE THIS

# Copyright (C) 2017 by Tom Davis,,, <tom@greyshirt.net>.
