#!/bin/ksh
# <@(#)tag:tw.csongor.uberbaud.foo,2024-02-27,01.50.40z/5f7511>

# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^Uhost^u
	         Big wrapper and such for easy tmuxing on remote ^Uhost^us over ssh.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
while getopts ':h' Option; do
	case $Option in
		h)	usage;															;;
		\?)	die USAGE "Invalid option: ^B-$OPTARG^b.";						;;
		\:)	die USAGE "Option ^B-$OPTARG^b requires an argument.";			;;
		*)	bad-programmer "No getopts action defined for ^T-$Option^t.";	;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
function main { # {{{1
	local tmux_bin obsd_path other_path

	obsd_path=/usr/bin
	other_path=/usr/local/bin
	case ${REMOTE:?} in
		${HOSTNAME:?})	die "$REMOTE is not remote.";		;;
		csongor.lan)	tmux_bin=$obsd_path/tmux;			;;
		sam.lan)		tmux_bin=$other_path/tmux;			;;
		uberbaud.foo)	tmux_bin=$obsd_path/tmux;			;;
		uberbaud.net)	tmux_bin=$obsd_path/tmux;			;;
		yt.lan)			tmux_bin=$obsd_path/tmux;			;;
		*)
			die "Remote host $REMOTE is not provisioned."
			;;
	esac
	SESSION_NAME=${REMOTE%%.*}

	in-new-term ssh-askfirst \
		ssh -t "$REMOTE" "$tmux_bin" -2u new-session -As "$SESSION_NAME"
	#   ^^^ ssh is a parameter to ssh-askfirst and cannot be a path to
	#       the ssh executable

} #}}}1

needs in-new-term ssh-askfirst

(($#))|| die 'Missing required parameter: ^Uhost^u.'
(($#>1))&& die 'Too many parameters. Expected only one (1): ^Uhost^u.'

typeset -ft in-new-term

REMOTE=$1
[[ $REMOTE == *.* ]]|| die "Remote is not fully qualified: ^V$REMOTE^v"

main; exit

# Copyright (C) 2024 by Tom Davis <tom@greyshirt.net>.
