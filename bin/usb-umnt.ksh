#!/bin/ksh
# @(#)[:rn*sP=c)av!rTPt%V25U: 2017-10-10 15:50:10 Z tw@csongor]
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^Udrive^u …^]
	         Unmount given drives mounted in ^B/vol/^b or selected drives
	         if none are given on the command line.
	       ^T$PGM -a^t
	         Unmount all drives mounted in ^B/vol/^b
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
do_all=false
# process -options {{{1
function bad_programmer {	# {{{2
	die 'Programmer error:'	\
		"  No getopts action defined for [1m-$1[22m."
  };	# }}}2
while getopts ':ah' Option; do
	case $Option in
		a)	do_all=true;											;;
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

# wrap script guts in a function so edits to this script file don't 
# affect running instances of the script.
function main {
	local awkpgm haves wants have want
	new-array haves wants

	awkpgm="$(cat)" <<-\
	\==AWK==
	NR==1			{next}
	/\/dev\/sd0/	{next}
					{sub(/^\/vol\//,"",$6);print $6}
	==AWK==
	+haves $(df -P|awk "$awkpgm")
	if haves-is-empty; then
		(($#==1)) && die 'No such drive mounted.'
		(($#)) && die 'No such drives mounted.'
		exit 0
	fi

	if $do_all; then
		+wants "${haves[@]}"
	elif (($#)); then	# use given
		for want in "$@"; do
			[[ -d $want ]]|| {
				warn "^B$want^b is not a mount point(1)."
				continue
			  }
			want="$(readlink -nf "$want")"
			for have in "${haves[@]}"; do
				[[ ${want#/vol/} == $have ]]|| continue 1
				+wants "$want"
				continue 2
			done
			warn "^B$want^b is not a mount point(2)."
		done
	else				# do selected
		sel-from-list -on "${haves[@]}"
		( set +u; ((${#reply[*]})); )|| die 'Nothing selected.'
		integer want_id
		for want_id in "${reply[@]}"; do
			+wants "${haves[want_id]}"
		done
	fi
	want-is-empty && return 1

	for want in "${wants[@]}"; do
		[[ $want == /* ]]|| want="/vol/$want"
		notify "Unmounting ^B$want^b."
		doas umount "$want" && doas rmdir "$want"
	done

}

main "$@"; exit

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
