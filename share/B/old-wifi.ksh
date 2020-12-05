#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-08-15:tw/02.33.43z/56c5885>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

wifi_config=${XDG_CONFIG_HOME:?}/wifi

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t ^[^T-f^t^] ^[^Unwid^u^|down^]
	         Connect to a wifi base station, perhaps the world.
	           The ^Unwid^u is the name of the base station.
	           ^T-f^t    Force. Kill the current connection, and reconnect.
	           ^Tdown^t  kill wifi and nothing else
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
warnOrDie=die
while getopts ':h' Option; do
	case $Option in
		f)	warnOrDie=warn;											;;
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
	case "$warnOrDie" in
		die)	die "$@" 'Use ^B-f^b to force a reconnect.';	;;
		warn)	warn "$@";										;;
		*)
			desparkle "$warnOrDie"
			die '^BProgrammer error^b:' "warnOrDie is ^B$REPLY^b."
			;;
	esac
} # }}}1
function get-wifi-device { # {{{1

	awkpgm="$(</dev/stdin)" <<-\
		\==AWK==
			/^[^ \t]/ {d=$1}
			/^\tmedia: IEEE802.11/ {print d}
		==AWK==

	set -- $(ifconfig -a|awk -F: "$awkpgm")

	(($#))||	die 'Could not find a ^Bwifi^b device.'
	(($#>1))&&	die 'Multiple ^Bwifi^b devices found. Bailing.'

	wifi="$1"
} # }}}1
# LOG-INET-STATS ←→ DELETE THIS {{{1
LOG_INET_STATS_RUNS=0
LOG_INET_STATS_awkpgm="$(</dev/stdin)" <<-\
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

# default
(($#))||	set -- fred
#(($#))||	die 'scanning is not yet implemented.'

(($#>1))&&	die 'Too many arguments. Expected at most one (1).'

[[ $1 == down ]]&& {
	get-wifi-device
	doas ifconfig $wifi down
	exit 0
  }

i-can-haz-inet&& warnOrDie "You're already connected to the Internet."

LOG-INET-STATS # ← DELETE THIS

set -A cfgs -- $wifi_config/[0-9][0-9],$1*
[[ ${cfgs[0]} == *\* ]]&& die 'Could not find a matching wifi configuration file.'
((${#cfgs[@]}>1))&& { set -A cfgs -- "$(omenu "${cfgs[@]}")" || exit 0; }

cfg="$(readlink -nf "${cfgs[0]}")"
[[ -n $cfg ]]|| die 'IMPOSSIBLE THING #1'

nwid="${cfg#$wifi_config/[0-9][0-9],}"
# there's a newline character, right ... about ... there
#     ↓
gsub '
' ' ' "$(sed -e '/^[[:space:]]*;/d' -e '/^[[:space:]]*$/d' "$cfg")"
eval "set -- $REPLY"

get-wifi-device

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
doas ifconfig $wifi nwid "$nwid" "$@"
doas ifconfig $wifi up
notify 'Getting an address.'
doas dhclient $wifi

LOG-INET-STATS # ← DELETE THIS

# Copyright (C) 2017 by Tom Davis,,, <tom@greyshirt.net>.
