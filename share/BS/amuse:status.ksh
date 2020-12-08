#!/bin/ksh
# @(#)[:81Id-|HViZqX}StB;Fpu: 2017-11-11 08:16:41 Z tw@csongor]
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Show amuse information.
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

needs amuse:env
amuse:env

cd "$AMUSE_RUN_DIR" || die "Could not ^Tcd^t to ^B$AMUSE_RUN_DIR^b."

integer X=0
for f in *; { ((X<${#f}))&& X=${#f}; }
integer COLUMNS=$(tput cols)
integer maxLen=$((COLUMNS-(X+7)))
typeset -L$X fLeft

TAB='	'
for f in *; do
	[[ $f == \* ]]&& break
	[[ -x $f ]]&& continue
	fLeft=$f
	if [[ -p $f ]]; then
		print -- "  $fLeft: \033[38;5;248m(\033[3mexists\033[23m)\033[0m"
		# printf "  %-${X}s: \e[38;5;248m(exists)\e[0m\n" "$f"
	elif [[ $f == *.core ]]; then
		rm -f "$f"
	elif [[ -s $f ]]; then
		fsize=$(stat -f %z "$f")
		if [[ $f == *.lst ]]; then
			text=$(wc -l <$f)
			text=${text##+( )}
			print -- "  $fLeft: \033[38;5;248m($text songs)\033[0m"
		elif [[ $f == playing ]]; then
			IFS="$TAB" read -r -- id info dur <$f
			idlen=${#id}
			infolen=${#info}
			mark=' '
			((idlen+infolen>maxLen))&& mark='…'
			typeset -R$((maxLen-(idlen))) rtext=$info
			info="${rtext##+([ [:punct:]])}"
			print -- "  $fLeft: \033[38;5;248m$id \033[38;5;217m$mark\033[34m$info\033[0m"
		else
			print -- "  $fLeft: \033[34m$(<$f)\033[0m"
		fi
	else
		print -- "  $fLeft: \033[38;5;217m-\033[0m"
	fi
done

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
