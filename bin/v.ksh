#!/bin/ksh
# @(#)[:GpEYZa*c{{hMx~)jN6Sk: 2017/08/02 18:23:45 tw@csongor.lan]
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

typeset -- VIMCACHE="${HOME}/.local/vim/cache"

[[ -d $VIMCACHE ]]|| die 'VIMCACHE does not exist.'
[[ -n $LOCALBIN ]] || die '[36m$LOCALBIN[39m is not set.'
[[ -d $LOCALBIN ]] || die '[36m$LOCALBIN[39m is not a directory.'
[[ :"$PATH": == *:"$LOCALBIN":* ]]|| PATH="${PATH%:}:$LOCALBIN"

[[ " ${DEBUG:-} " == *' v.zsh '* ]]&& set -x

typeset -- this_pgm="${0##*/}"
function usage { # {{{1
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle <<-\
	==SPARKLE==
	^F{4}Usage^f: ^T${PGM}^t  ^[^T-f^t^] ^Ufile^u ^[^Umessage^u^]
	         ^T-f^t  Force edit even if ^Ufile^u isn't text.
	       ^T${PGM} -h^t
	         Show this help message.
	==SPARKLE==
	exit 0
} # }}}
# process -options {{{1
function bad_programmer {	# {{{2
	die 'Programmer error:'	\
		"  No getopts action defined for [1m-$1[22m."
  };	# }}}2
typeset -- warnOrDie='die';
typeset hasmsg=false rcsmsg=''
while getopts ':m:fh' Option; do
	case $Option in
		f)	warnOrDie='warn';										;;
		m) hasmsg=true; rcsmsg="$OPTARG";							;;
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
		die)  die "$@" 'Use [1m-f[22m to force an edit.';		;;
		warn) warn "$@";											;;
		*)    die '[1mProgrammer error[22m:' \
					'warnOrDie is [1m${warnOrDie}[22m.';		;;
	esac
} # }}}1

(($#))||		die 'Missing required argument [4mfile-name[24m.'
[[ -a $1 ]]||	die "No such file [1m${1}[22m."

typeset hasmsg=false rcsmsg=''
(($#>1))&& {
	hasmsg=true
	set -A rcsmsg_a -- "$@"
	unset rcsmsg_a[1]
	typeset -- rcsmsg="${rcsmsg_a[*]}"
	unset rcsmsg_a
}

function X { # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	# wrap script guts in anonymous function so edits on the file don't 
	# affect running instances.

typeset -- f_fullpath="$( readlink -fn -- $1 )"

[[ -n $f_fullpath ]]||	die 'Could not follow link.'
[[ -f $f_fullpath ]]||	die "[1m${1}[22m is [1mnot[22m a file."
[[ $f_fullpath == *,v ]]&& warnOrDie "Seems to be an [1mRCS archive[22m file."
typeset -- ftype="$( /usr/bin/file -b $f_fullpath )"
[[ $ftype == *text* || $ftype == *XML* ]]||
						warnOrDie "Does not seem to be a text file."

# because we've `readlink`ed the arg, it's guaranteed to have at least 
# one (1) forward slash ('/') as (and at) the root.
typeset -- f_path=${f_fullpath%/*}
typeset -- f_name=${f_fullpath##*/}

typeset -- swapglob="$f_fullpath" p='' s=''
while [[ $swapglob == */* ]]; do
	p="${swapglob%%/*}"; s="${swapglob#*/}"; swapglob="${p}%${s}"
done
swapglob="$swapglob"
set -A swaps -- $VIMCACHE/$swapglob.s??

[[ ${swaps[1]} == $VIMCACHE/$swapglob'.s??' ]]&&
	die 'Swap files exist. Vim or Crash?'

cd $f_path || die "Could not [32mcd[39m to [1m${f_path}[22m."

typeset -- has_rcs=false
[[ -d RCS && -f RCS/$f_name,v ]] && {
	has_rcs=true
	rcsdiff -q ./$f_name ||
		die 'RCS and checked out versions differ.'
	co -q -l ./$f_name ||
		die "Could not [32mco -l[39m [1m${f_name}[22m."
  }

#typeset -- stemma="$( egrep -o '@\(#\)\[:[^]]+]' "$f_name")"
#stemma="${stemma#*:}"; stemma="${stemma%%:*}"

# we could just use ./$f_name
# BUT then the vim process would not have a command including the path, 
# SO, let's use $f_fullpath
vim "$f_fullpath"

trackfile "$f_fullpath"

if [[ -d RCS ]]; then
	# use an array so expansion will work without weird quoting issues
	set -A rcsopts -- -u
	if $has_rcs; then
		$hasmsg && set -A rcsopts -- "${rsopts[@]}" -m"$rcsmsg"
		rcsdiff -q ./$f_name
		ci -q -j "${rcsopts[@]}" ./$f_name
	else
		# without the dash at the beginning of rcsmsg, the message would 
		# be taken from a file named in $rcsmsg
		$hasmsg && set -A rcsopts -- -t-"$rcsmsg"
		ci -q -i "${rcsopts[@]}" ./$f_name
	fi
elif $hasmsg; then
	warn 'No [35mRCS/[39m.'
fi

#cd $start_wd # no need if 
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
}

X "$@" # run the script-as-anonymous-function

# Copyright (C) 2016 by Tom Davis <tom@greyshirt.net>.
