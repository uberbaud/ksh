#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-07-31:tw/19.16.21z/4b16eb0>
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
function already-in-edit { # {{{1
	warn "File is already being edited (pid=^B$1^b)"
	needs flash-parent-window-of-pid
	flash-parent-window-of-pid "$1"
	integer rc=$?
	((rc))&&
		warn "Edit window is on desktop ^B$rc^b"
	die "Quitting."
} # }}}1
function clear-dead-edit { # {{{1
	local ovpid=$1 lockfile="$2" ovcmd
	ovcmd=$(/bin/ps -o command= -p $ovpid)
	# if there's really an edit session, return 1 (we didn't clear a
	# dead edit).
	[[ ${ovcmd:-} == /bin/ksh\ /home/tw/bin/ksh/v\ * ]]&& return 1
	# otherwise, the lockfile is bogus, so clear it
	rm "$lockfile"
	return 0
} # }}}1
function safe-to-edit { #{{{1
	local F ovpid
	F="${1:?Programmer error. Missing parameter.}"
	gsub % %% "$F"
	gsub / %  "$REPLY"
	LOCKNAME="$REPLY"
	V_CACHE="$XDG_CACHE_HOME/v"
	[[ -d $V_CACHE ]]|| mkdir -p $V_CACHE
	while ! get-exclusive-lock-or-exit "$LOCKNAME" $V_CACHE; do
		ovpid=$(<$REPLY)
		clear-dead-edit $ovpid $REPLY ||
			already-in-edit $ovpid
	done
	LOCKFILE="$REPLY"
	print $$>$LOCKFILE
}
function check-flags-for-writability { # {{{1
	local UCHG=16#2 UAPPND=16#4 SCHG=16#20000 SAPPND=16#40000
	local NOWRITES=$((UCHG|UAPPND|SCHG|SAPPND))
	local flags=$(stat -f %f "$1")
	((flags&NOWRITES))|| return 0

	flagstr=''
	((flags&UCHG))&&	flagstr="$flagstr,uchg"
	((flags&UAPPND))&&	flagstr="$flagstr,uappnd"
	((flags&SCHG))&&	flagstr="$flagstr,schg"
	((flags&SAPPND))&&	flagstr="$flagstr,sappnd"
	die "File is flagged ^B${flagstr#,}^b. It is not writable."
} # }}}1
function verify-file-is-editable { # {{{1
	local ftype
	[[ -f $f_fullpath ]]||	die "^B$1^b is ^Bnot^b a file."
	[[ $f_fullpath == *,v ]]&&
		warnOrDie "Seems to be an ^BRCS archive^b file."
	ftype="$(/usr/bin/file -b "$f_fullpath")"

	[[ $ftype == *text* || $ftype == *XML* ]]||
		warnOrDie "Does not seem to be a text file."
} # }}}1

# TODO: test 'checked-out'ness with something like	
#       [[ -n $(rlog -L -l bobslunch.rem) ]]		

needs $ED ci co rcsdiff trackfile

(($#))|| exec "$ED" # We don't have a file, so short circut all the rest.


[[ -a $1 ]]|| die "No such file ^B$1^b."
f_fullpath="$(readlink -fn -- "$1" 2>/dev/null)" ||
	die "Could not ^Treadlink^t ^B$1^b."
shift

verify-file-is-editable "$f_fullpath"
check-flags-for-writability "$f_fullpath"
safe-to-edit "$f_fullpath"

hasmsg=false
rcsmsg=''
(($#))&& { hasmsg=true; rcsmsg="$*"; }

# because we've `readlink`ed the arg, it's guaranteed to have at least 
# one (1) forward slash ('/') as (and at) the root.
f_path="${f_fullpath%/*}"
f_name="${f_fullpath##*/}"

cd "$f_path" || die "Could not ^Tcd^t to ^B${f_path}^b."

has_rcs=false
[[ -d RCS && -f RCS/"$f_name,v" ]] && {
	has_rcs=true
	rcsdiff -q ./"$f_name" ||
		warnOrDie 'RCS and checked out versions differ.'
	# avoid "writable ./f_name exists; remove it? [ny](n):"
	[[ -w ./"$f_name" ]]&& chmod a-w ./"$f_name"
	co -q -l ./"$f_name" ||
		die "Could not ^Tco -l^t ^B${f_name}^b."
  }

# we could just use ./$f_name
# BUT then the vim process would not have a command including the path, 
# which we can use for finding the X11 window, SO, let's use $f_fullpath

# SHA1 is the fastest on my system (amd64) of any of the cksum
# algorithms, more than twice as fast as sha224 or sha256, and nearly
# twice as fast as the 64 bit SHAs (384, 512/256, 512). But it's even
# faster than md5, or the traditional cksum algorithm.

function main {

	CKSUM_BEFORE="$(cksum -qa sha1b "$f_fullpath")"
	$ED "$f_fullpath"
	CKSUM_AFTER="$(cksum -qa sha1b "$f_fullpath")"
	[[ $CKSUM_BEFORE != $CKSUM_AFTER ]]&& {
		trackfile "$f_fullpath"
		[[ -f .LAST_UPDATED ]]&& date -u +"$ISO_DATE" >.LAST_UPDATED
	  }

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

	[[ -n ${LOCKNAME:-} ]]&& release-exclusive-lock "$LOCKNAME" $V_CACHE
}

main "$@"; exit 0

# Copyright (C) 2016 by Tom Davis <tom@greyshirt.net>.