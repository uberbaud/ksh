#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-07-31:tw/19.16.21z/4b16eb0>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from KSH}

BIN=$(realpath -q "$0")
[[ $(whence $VISUAL) == $BIN ]]&& unset VISUAL
[[ $(whence $EDITOR) == $BIN ]]&& unset EDITOR
ED=${VISUAL:-${EDITOR:?Neither VISUAL nor EDITOR is set.}}

typeset -- this_pgm=${0##*/}
function usage { # {{{1
	desparkle "$this_pgm"
	PGM=$REPLY
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

	       ^GEnvironment:^g ^VDESCRIPTION^v ^Gwill be used as the^g
	           ^Ginitial commit description if there is an initial commit.^g
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
function already-in-edit { # {{{1
	set -- $(<$1)
	warn "File is already being edited (pid=^B$1^b)"
	needs flash-parent-window-of-pid
	flash-parent-window-of-pid "$1"
	integer rc=$?
	((rc))&&
		warn "Edit window is on desktop ^B$rc^b"
	die "Quitting."
} # }}}1
function safe-to-edit { #{{{1
	local F
	F=${1:?Programmer error. Missing parameter.}
	gsub % %% "$F"
	gsub / %  "$REPLY"
	LOCKNAME=$REPLY
	V_CACHE=$XDG_CACHE_HOME/v
	needs-path -create -or-die "$V_CACHE"
	get-exclusive-lock -no-wait "$LOCKNAME" $V_CACHE ||
		already-in-edit "$REPLY"
}
function check-flags-for-writability { # {{{1
	local UCHG=16#2 UAPPND=16#4 SCHG=16#20000 SAPPND=16#40000
	local NOWRITES=$((UCHG|UAPPND|SCHG|SAPPND))
	local flags=$(stat -f %f "$1")
	((flags&NOWRITES))|| return 0

	flagstr=''
	((flags&UCHG))&&	flagstr=$flagstr,uchg
	((flags&UAPPND))&&	flagstr=$flagstr,uappnd
	((flags&SCHG))&&	flagstr=$flagstr,schg
	((flags&SAPPND))&&	flagstr=$flagstr,sappnd
	die "File is flagged ^B${flagstr#,}^b. It is not writable."
} # }}}1
function verify-file-is-editable { # {{{1
	[[ -f $f_fullpath ]]||	die "^B$1^b is ^Bnot^b a file."
	[[ $f_fullpath == *,v ]]&&
		warnOrDie "File seems to be an ^BRCS archive^b file."
	
	file-is-valid-utf8 "$f_fullpath" ||
		warnOrDie "File is not valid UTF-8 text."
} # }}}1
function handle-modified { #{{{1
	warnOrDie 'Checked-in and working versions differ.'
	NOT-IMPLEMENTED
} #}}}1
function init-or-sync-then-checkout { #{{{1
	case ${STATUS:-nope} in
		untracked)	$vms-add "$filename" "${DESCRIPTION:=$(term-get-text descr)}"; ;;
		modified)	handle-modified "$filename";							;;
		ok)			:;														;;
		nope)		warn "^T$vms-status^t does not set ^O$^o^VSTATUS^v.";	;;
		*)			warn "^T$vms-status^t: ^O$^o^VSTATUS^v=^U$STATUS^u.";	;;
	esac
	$vms-checkout "$filename"
} # }}}1
function vms-checkin-all { # {{{1
	VMSes=
	if versmgmt-init; then
		HAS_VERSMGMT=true
		versmgmt-active-vmses && {
			FOREACH_VMS=init-or-sync-then-checkout 
			versmgmt-apply status ./$f_name
		  }
	else
		HAS_VERSMGMT=false
		warn "^BVERSMGMT^b: $ERRMSG"
	fi
} # }}}1
function main { # {{{1
	vms-checkin-all "$f_name"
	CKSUM_BEFORE=$(fast-crypt-hash "$f_fullpath")

	$ED "$f_fullpath"

	CKSUM_AFTER=$(fast-crypt-hash "$f_fullpath")
	if [[ $CKSUM_BEFORE != $CKSUM_AFTER ]]; then
		trackfile "$f_fullpath"
		[[ -f .LAST_UPDATED ]]&& date -u +"$ISO_DATE" >.LAST_UPDATED

		if $HAS_VERSMGMT; then
			versmgmt-apply checkin "$f_name" "${ciMsg:-}"
		elif [[ -n $ciMsg ]]; then
			warn 'Supplied a ^Bcheckin^b message, but there'\''s no ^IVMS^i.'
		fi
	elif [[ -n $ciMsg ]]; then
		warn 'Supplied a ^Bcheckin^b message, but there were no changes made.'
	fi

	[[ -n ${LOCKNAME:-} ]]&& release-exclusive-lock "$LOCKNAME" $V_CACHE
} # }}}1

needs $ED
(($#))|| exec "$ED" # We don't have a file, so short circut all the rest.

needs	\
	fast-crypt-hash file-is-valid-utf8 get-exclusive-lock needs-cd		\
	needs-path release-exclusive-lock trackfile versmgmt-init warnOrDie

[[ -a $1 ]]|| die "No such file ^B$1^b."
f_fullpath=$(realpath -q -- "$1") || die "Could not ^Trealpath^t ^B$1^b."
shift

verify-file-is-editable		"$f_fullpath"
check-flags-for-writability	"$f_fullpath"
safe-to-edit				"$f_fullpath"

ciMsg=$*

# because we've `realpath`ed the arg, it's guaranteed to have at least 
# one (1) forward slash ('/') as (and at) the root.
f_path=${f_fullpath%/*}
f_name=${f_fullpath##*/}

needs-cd -or-die "$f_path"

# we could just use ./$f_name
# BUT then the vim process would not have a command including the path, 
# which we can use for finding the X11 window, SO, let's use $f_fullpath

main; exit 0

# Copyright (C) 2016 by Tom Davis <tom@greyshirt.net>.
