#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2020-12-03,19.43.25z/3214cb1>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: "${FPATH:?Run from within KSH}"

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm" PGM
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^Ufgrep_options^u^] ^Ucmd_name^u
	         Check ^O$^o^VK^v, ^O$^o^VB^v, ^O$^o^VF^v, and ^O$^o^VHOST^v variants for ^Ucmd_name^u
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}1
# process -options {{{1
while getopts ':h' Option; do
	case $Option in
		h)	usage;															;;
		\?)	die USAGE "Invalid option: ^B-$OPTARG^b.";						;;
		:)	die USAGE "Option ^B-$OPTARG^b requires an argument.";			;;
		*)	bad-programmer "No getopts action defined for ^T-$OPtion^t.";	;;
	esac
done
# remove already processed arguments
shift $((OPTIND_1))
# ready to process non '-' prefixed arguments
# /options }}}1
function main { # {{{1
	local cmd eopts f link alt IFS
	IFS=$NL
	# pop cmd from args.
	cmd=$*
	(($#>1))&& {
		eopts=${cmd%$NL*}
		cmd=${cmd##*$NL}
	  }
	# find other names for cmd_name, POSSIBLE FALSE POSITIVES
	for f in ${LOCALBIN:?}/* ${USRBIN:?}/* ${HOME:?}/bin/*; do
		[[ -h $f ]]|| continue
		link=$(realpath $f)
		link=${link##*/}
		f=${f##*/}
		# the soft link points to the cmd
		[[ $link == $cmd ]]&&	alt="${alt:-}$NL$f"
		# the cmd IS a soft link, so include the file pointed to
		[[ $f == $cmd ]]&&		alt="${alt:-}$NL$link"
	done
	cmd="$cmd${alt:-}"

	[[ -n ${DEBUG:-} ]]&& {
		desparkle "$cmd"
		notify "looking for: ^I^N$REPLY^n^i"
	  }

	builtin cd ${KDOTDIR:?}
	set --								\
		bin/*							\
		functions/*						\
		{csongor,yt,uberbaud}/{B,F}/*	\
		{.,csongor,yt,uberbaud}/kshrc
	set -- $(for f; do
				[[ -f $f ]]||				continue
				for link in $cmd; do
					[[ $f == */$link ]]&&	continue 2
				done
				[[ $f == *\* ]]&&			continue
				print -r -- "$f"
			done);
	fgrep -w ${eopts:-} "$cmd" "$@"
} # }}}1

NL='
'
TAB='	'
(($#))|| die 'Missing required parameter ^Ucmd_name^u.'
main "$@"; exit

# Copyright © 2020 by Tom Davis <tom@greyshirt.net>.
