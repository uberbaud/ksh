#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2019-12-04,00.38.48z/38a1f07>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

ACTION=start

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-k^t^|^T-r^t^]
	         Starter for ^Samuse^s.
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
while getopts ':krh' Option; do
	case $Option in
		k)	ACTION=stop;										;;
		r)	ACTION=restart;										;;
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
function start { #{{{1
	local BUF
	exec >~/log/amuse.log 2>&1 </dev/null

	BUF="$(head -n 3 played.lst)"
	>played.lst print -- "$BUF"

	if [[ -s ui-pid ]]; then
		print 'Already running: amuse-ui'
	else
		print 'Starting: amuse-ui'
		nohup /usr/local/bin/st					\
			-c amuse-ui							\
			-T amuse							\
			-e ~/.config/ksh/bin/amuse-ui.ksh	&
	fi

	if [[ -s server-pid ]]; then
		print 'Already running: amuse-server'
	else
		print 'Starting: amuse-server'
		nohup ~/.config/ksh/bin/amuse-server.ksh &
	fi

} #}}}1
function stop { #{{{1
	local p F N
	for p in server ui; do
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
function restart { stop; start; }

needs amuse:env
amuse:env
cd "${AMUSE_RUN_DIR:?}" || die 'Could not ^Tcd^t to ^S$AMUSE_RUN_DIR^s.'

$ACTION; exit

# Copyright (C) 2019 by Tom Davis <tom@greyshirt.net>.
