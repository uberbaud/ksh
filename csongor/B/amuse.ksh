#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2019-12-04,00.38.48z/38a1f07>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

ACTION=Start

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-c^t^|^T-k^t^|^T-r^t^]
	         Starter for ^Samuse^s.
	           ^T-c^t  Clean up ^S\$AMUSE_RUN_DIR^s.
	           ^T-k^t  Kill any running instances.
	           ^T-r^t  Restart (stop then start).
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
while getopts ':ckrh' Option; do
	case $Option in
		c)	ACTION=CleanUp;										;;
		k)	ACTION=Stop;										;;
		r)	ACTION=Restart;										;;
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
function start-ui { #{{{1
	[[ -s ui-pid ]]&& {
		local PROCNAME
		# ui-pid is set, but is it really running?
		PROCNAME="$(ps -ocommand= -p $(<ui-pid) 2>/dev/null)" && {
			[[ $PROCNAME == */amuse-ui.ksh ]]&&
				return 1 # ui-pid points to a running amuse-ui

			# bad PID, or PID points to something else, so CLEAR IT
			print 'Clearing ui-pid'
			: >ui-pid
		  }
	  }

	print 'Starting: amuse-ui'
	nohup >/dev/null 2>&1					\
		/usr/local/bin/st					\
		-c amuse-ui							\
		-T amuse							\
		-e ~/.config/ksh/bin/amuse-ui.ksh	\
		&

} #}}}1
function start-server { #{{{1
	[[ -s server-pid ]]&& {
		local PROCNAME
		# server-pid is set, but is it really running?
		PROCNAME="$(ps -ocommand= -p $(<server-pid) 2>/dev/null)" && {
			[[ $PROCNAME == */amuse-server.ksh ]]&&
				return 1 # server-pid points to a running amuse-server

			# bad PID, or PID points to something else,
			# --- so clear everything ---
			print 'Clearing server-pid and sigpipe'
			: >server-pid
			rm -f sigpipe
		  }
	  }
	print 'Starting: amuse-server'
	nohup >~/log/amuse-server.log 2>&1		\
		~/.config/ksh/bin/amuse-server.ksh	&
} #}}}
function start-watchtime { #{{{1
	[[ -s watchtime-pid ]]&& {
		local PROCNAME
		# watchtime-pid is set, but is it really running?
		PROCNAME="$(ps -ocommand= -p $(<watchtime-pid) 2>/dev/null)" && {
			[[ $PROCNAME == */amuse-watchtime.ksh ]]&&
				return 1 # ui-pid points to a running amuse-ui

			# bad PID, or PID points to something else, so CLEAR IT
			print 'Clearing watchtime-pid'
			: >watchtime-pid
		  }
	  }

	print 'Starting: amuse-watchtime'
	nohup >~/log/amuse-watchtime.log 2>&1	\
	~/.config/ksh/bin/amuse-watchtime.ksh	&

} #}}}1
function CleanUp { # {{{1
	local server=false ui=false player=false watchtime=false S
	# Server
	[[ -s server-pid ]]&& {
		server=true
		S=$(ps -o command= $(<server-pid) 2>/dev/null)
		[[ -z $S ]]&& server=false
	  }
	if $server; then
		notify '@muse ^Bserver^b is running' 'Skipping.'
	else
		notify '@muse ^Bserver^b is not running' 'cleaning up.'
		: >final >server-pid
		[[ -e sigpipe ]]&& rm sigpipe
		[[ -s paused-at ]]||
			: >playing
	fi

	# Player
	[[ -s player-pid ]]&& {
		player=true
		S=$(ps -o command= $(<player-pid) 2>/dev/null)
		[[ -z $S ]]&& player=false
	  }
	if $player; then
		notify '@muse ^Bplayer^b is running' 'Skipping.'
	else
		notify '@muse ^Bplayer^b is not running' 'cleaning up.'
		: >player-pid
		[[ -s paused-at ]]||
			: >playing >timeplayed
	fi

	# UI
	[[ -s ui-pid ]]&& {
		ui=true
		S=$(ps -o command= $(<ui-pid) 2>/dev/null)
		[[ -z $S ]]&& ui=false
	  }
	if $ui; then
		notify '@muse ^Bui^b is running' 'Skipping.'
	else
		notify '@muse ^Bui^b is not running' 'cleaning up.'
		: >ui-pid
	fi

	# WATCHTIME
	[[ -s watchtime-pid ]]&& {
		watchtime=true
		S=$(ps -o command= $(<watchtime-pid) 2>/dev/null)
		[[ -z $S ]]&& watchtime=false
	  }
	if $watchtime; then
		notify '@muse ^Bwatchtime^b is running' 'Skipping.'
	else
		notify '@muse ^Bwatchtime^b is not running' 'cleaning up.'
		: >watchtime-pid
	fi
} #}}}1
function Start { #{{{1
	local BUF

	BUF="$(head -n 3 played.lst)"
	>played.lst print -- "$BUF"

	start-ui
	start-server
	start-watchtime

} #}}}1
function Stop { #{{{1
	local p F N
	for p in server ui watchtime; do
		F="$p-pid"
		N="amuse-$p"
		if [[ -s $F ]]; then
			2>&1 print "Stopping: $N"
			kill -TERM $(<$F)
		else
			2>&1 print "Not running: $N"
		fi
	done
} #}}}1
function Restart { Stop; Start; }

needs amuse:env
amuse:env
cd "${AMUSE_RUN_DIR:?}" || die 'Could not ^Tcd^t to ^S$AMUSE_RUN_DIR^s.'

#typeset -f -t start-ui start-server start-watchtime	\
#	CleanUp Start Stop Restart
#set -x

$ACTION; exit

# Copyright (C) 2019 by Tom Davis <tom@greyshirt.net>.
