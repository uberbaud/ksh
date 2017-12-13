#!/bin/ksh
# @(#)[:GpEYZa*c{{hMx~)jN6Sk: 2017/08/02 18:23:45 tw@csongor.lan]
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from KSH}
ED="${VISUAL:-${EDITOR:?Neither VISUAL nor EDITOR is set.}}"

[[ -n $LOCALBIN ]] || die '^S$LOCALBIN^s is not set.'
[[ -d $LOCALBIN ]] || die '^S$LOCALBIN^s is not a directory.'
[[ :"$PATH": == *:"$LOCALBIN":* ]]|| PATH="${PATH%:}:$LOCALBIN"

[[ " ${DEBUG:-} " == *' v.zsh '* ]]&& set -x

typeset -- this_pgm="${0##*/}"
function usage { # {{{1
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle <<-\
	==SPARKLE==
	^F{4}Usage^f: ^T${PGM}^t  ^[^T-f^t^] ^Ufile^u ^[^Umessage^u^]
	         Edits a file and handles RCS checkout/checkin.
	         ^T-f^t  Force edit even if ^Ufile^u isn't text.
	       ^T${PGM}^t  ^[^T-f^t^] ^T=^t^Ucommand^u ^[^Umessage^u^]
	         Edits a command in ^SPATH^s or a function in ^SFPATH^s.
	         ^T-f^t  Force edit even if ^Ufile^u isn't text.
	       ^T${PGM} -h^t
	         Show this help message.
	==SPARKLE==
	exit 0
} # }}}
# process -options {{{1
function bad_programmer {	# {{{2
	die 'Programmer error:'	\
		"  No getopts action defined for ^B-$1^b."
  };	# }}}2
typeset -- warnOrDie='die';
while getopts ':fh' Option; do
	case $Option in
		f)	warnOrDie='warn';										;;
		h)	usage;													;;
		\?)	die "Invalid option: ^B-$OPTARG^b.";				;;
		\:)	die "Option ^B-$OPTARG^b requires an argument.";	;;
		*)	bad_programmer "$Option";								;;
	esac
done
# remove already processed arguments
shift $(($OPTIND - 1))
# ready to process non '-' prefixed arguments
# /options }}}1
function warnOrDie { #{{{1
	case $warnOrDie in
		die)  die "$@" 'Use ^B-f^b to force an edit.';		;;
		warn) warn "$@";											;;
		*)    die '^BProgrammer error^b:' \
					'warnOrDie is ^B${warnOrDie}^b.';		;;
	esac
} # }}}1
function safe-to-edit-vim {
	local F="$1"
	[[ $F == $HOME/* ]]&& F="~$USER/${F#$HOME/}"
	! (vim -r|egrep "$F")
}
function safe-to-edit-nvim { #{{{1
	local swaps s p d w
	set -A reply --
	needs ls-nvim-swaps
	new-array swaps
	splitstr NL "$(ls-nvim-swaps "$1")" swaps
	if swaps-not-empty; then
		reply_next_id=0
		reply[reply_next_id++]="Swap files found:"
		for s in "${swaps[@]}"; do
			d=''
			w=''
			p="${s##* }"
			s="${s% $p}"
			desparkle "$s"; s="$REPLY"
			if [[ $p != - ]]; then
				needs x11-windowid-for-pid x11-flash-window
				x11-windowid-for-pid $p && {
					w=$REPLY
					d=$(xdotool get_desktop_for_window $w); ((d++))
					x11-flash-window -dq $w &
				  }
			else
				p=''
			fi
			reply[reply_next_id]="$s p^S$p^s d^B$d^b"
		done
		return 1
	else
		return 0
	fi
} #}}}1
function safe-to-edit { #{{{1
	local call="safe-to-edit-$EDBIN"
	[[ $(whence -v "$call") == *' function' ]]|| {
		warnOrDie "^B$call^b is not implemented."
		return 0
	  }
	"$call" "$@"
} #}}}1

needs $ED
EDBIN="${ED##*/}"
(($#))|| exec "$ED"

function main {

typeset -- f_fullpath errmsg
if [[ -a $1 ]]; then
	f_fullpath="$( readlink -fn -- "$1")"
	errmsg='Could not follow link.'
elif [[ $1 == =* ]]; then
	f_fullpath="$(command -v "${1#=}")"
	if [[ -z $f_fullpath ]]; then
		die 'No such command nor function.'
	elif [[ $f_fullpath == /* ]]; then
		f_fullpath="$(readlink -fn -- "$f_fullpath")"
		errmsg='Could not follow command'\''s link.'
	else
		f_fullpath="$(find-function "${1#=}")"
		errmsg='Could not find function.'
	fi
else
	die "No such file ^B${1}^b."
fi

[[ -n $f_fullpath ]]||	die "$errmsg"
[[ -f $f_fullpath ]]||	die "^B$1^b is ^Bnot^b a file."
[[ $f_fullpath == *,v ]]&& warnOrDie "Seems to be an ^BRCS archive^b file."
typeset -- ftype="$( /usr/bin/file -b "$f_fullpath")"
[[ $ftype == *text* || $ftype == *XML* ]]||
						warnOrDie "Does not seem to be a text file."
shift

safe-to-edit "$f_fullpath" || die "${reply[@]}"

typeset hasmsg=false rcsmsg=''
(($#))&& { hasmsg=true; rcsmsg="$*"; }

# because we've `readlink`ed the arg, it's guaranteed to have at least 
# one (1) forward slash ('/') as (and at) the root.
typeset -- f_path="${f_fullpath%/*}"
typeset -- f_name="${f_fullpath##*/}"

cd "$f_path" || die "Could not ^Tcd^t to ^B${f_path}^b."

typeset -- has_rcs=false
[[ -d RCS && -f RCS/"$f_name,v" ]] && {
	has_rcs=true
	rcsdiff -q ./"$f_name" ||
		die 'RCS and checked out versions differ.'
	co -q -l ./"$f_name" ||
		die "Could not ^Tco -l^t ^B${f_name}^b."
  }

# we could just use ./$f_name
# BUT then the vim process would not have a command including the path, 
# which we can use for finding the X11 window, SO, let's use $f_fullpath
$ED "$f_fullpath"

trackfile "$f_fullpath"

if [[ -d RCS ]]; then
	new-array rcsopts
	+rcsopts -q -u
	if $has_rcs; then
		$hasmsg && +rcsopts -m"$rcsmsg"
		rcsdiff -q ./"$f_name"
		ci "${rcsopts[@]}" -j ./"$f_name"
	else
		# without the dash at the beginning of rcsmsg, the message would 
		# be taken from a file named in $rcsmsg
		$hasmsg && +rcsopts -t-"$rcsmsg"
		ci "${rcsopts[@]}" -i ./"$f_name"
	fi
elif $hasmsg; then
	warn 'No ^SRCS/^s.'
fi

}

main "$@"; exit 0

# Copyright (C) 2016 by Tom Davis <tom@greyshirt.net>.
