#!/bin/ksh
# @(#)[:G;LweTE5#GhAdml`<%M!: 2017-10-15 21:49:54 Z tw@csongor]
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH} ${VISUAL:-${EDITOR:?Neither VISUAL nor EDITOR is set}}
set -A vopts --

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^Ufile^u ^[^Ucheckin message^u^]
	         Edit a copy of a file in ^B~/hold^b, then overwrite the original
	         with the copy. (More secure that ^Tdoas vim ^Ufile^u^t).
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

(($#))|| die 'Missing required argument ^Ufile^u.'
needs ci co ${VISUAL:-${EDITOR:?Neither VISUAL nor EDITOR variable is set}}

CI_INITIAL_DESCRIPTION='OpenBSD system file'

desparkle "$1"
filenameD="$REPLY"
filename="$(readlink -fn "$1")"; shift
[[ -n $filename ]]|| die "Invalid file name ^B$filenameD^b."
[[ -a $filename ]]&& {
	[[ -f $filename ]]|| die "^B$filenameD^b is not a file."
  }

filepath="${filename%/*}"
[[ $filepath == $HOME* ]] &&
	die "^T$PGM^t only works outside of ^S\$HOME^s." \
		"Instead, use ^T:W^t inside ^Tvim^t (^Tv^t or ^Tnew^t)."

[[ -d $filepath ]]|| die "^B$filepath^b is not a directory."

function as-root {
	doas true || doas true || doas true || return 255
	doas "$@"
}

function main {
	holdbase="$HOME/hold/$(uname -r)/sys-files"

	workingpath="$holdbase/$filepath"
	[[ -d $workingpath/RCS ]]||
		mkdir -p "$workingpath/RCS" ||
			die "Could not ^Tmkdir -p ^U$workingpath/RCS^u^t."

	cd "$workingpath" || die "Could not ^Tcd^t to ^B$workingpath^b."

	workfile="${filename##*/}"
	[[ -a $workfile ]]&& {
		[[ -f $workfile ]]||
			die "working file (^B$workfile^b) exits in"	\
				"^B$workingpath^b"							\
				"but is not a file."
	  }

	[[ -f $workfile ]]&& {
		[[ -f RCS/$workfile,v ]]||
			ci -q -u -i -t"-$CI_INITIAL_DESCRIPTION" ./"$workfile"
		co -q -l ./"$workfile" || die "^Tco^t error."
	}
	PREF=''
	if [[ -f $filename ]]; then
		fowner="$(stat -f'%Su' "$filename")"
		fgroup="$(stat -f'%Sg' "$filename")"
		fperm="$(stat -f'%#Lp' "$filename")"
		touch ./"$workfile"
		[[ -r $filename ]]|| PREF=as-root
		if [[ -s $filename ]]; then
			$PREF cat $filename >$workfile
		else
			echo >$workfile
		fi
		SHA384="$(cksum -qa sha384b ./"$workfile")"
		[[ -f RCS/$workfile,v ]]&& {
			rcsdiff -q ./"$workfile" ||
				die "sysytem file and archived file have diverged."	\
					"Do an RCS ^Tci^t and rerun."
		  }
	else
		SHA384=''
		fowner=root
		fgroup=wheel
		fperm=0644
		echo >$workfile
	fi

	${VISUAL:-$EDITOR} ./"$workfile"
	if [[ -f RCS/$workfile,v ]]; then
		# previously checked in
		rcsdiff -q ./"$workfile" ||
			ci -q -u -j ${1:+-m"$*"} ./"$workfile"
	else
		ci -q -u -i -t"-${*:-$CI_INITIAL_DESCRIPTION}" ./"$workfile"
	fi
	[[ -n $SHA384 ]]&& {
		[[ $SHA384 == "$(cksum -qa sha384b ./"$workfile")" ]]&& {
			notify 'There were no changes made.' 'Exiting.'
			exit 0
		  }
		[[ $SHA384 != "$($PREF cksum -qa sha384b "$filename")" ]]&& {
			warn "^B$filenameD^b has changed since reading."
			desparkle "$workingpath/$workfile"
			yes-or-no Continue ||
				die "You must manually copy"	\
					"  ^B$REPLY^b"				\
					"to"						\
					"  ^B$filenameD^b"
		  }
	  }
	if [[ -w $filename ]]; then
		cat ./"$workfile" >"$filename"
	else
		set -- -p -F -o "$fowner" -g "$fgroup" -m $fperm -S
		as-root install "$@" ./"$workfile" "$filename"
	fi
}

main "$@"; exit

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
