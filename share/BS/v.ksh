#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-07-31:tw/19.16.21z/4b16eb0>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from KSH}

BIN=$(realpath -q "$0")
[[ $(whence $VISUAL) == $BIN ]]&& unset VISUAL
[[ $(whence $EDITOR) == $BIN ]]&& unset EDITOR
ED=${VISUAL:-${EDITOR:?Neither VISUAL nor EDITOR is set.}}
WOD_ACTION='edit'

typeset -- this_pgm=${0##*/}
function usage { # {{{1
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle <<-\
	==SPARKLE==
	^F{4}Usage^f: ^T${PGM}^t ^[^T-f^t^] ^[^T-k^t ^Uwfid^u^] ^Ufile^u ^[^Umessage^u^]
	         Edits a file and handles VMS checkout/checkin.
	         ^T-f^t  Force edit even if ^Ufile^u isn't text.
	         ^T-k^t  On exit, runs:
	             ^Tpkill -HUP -lf -- "^^watchfile -i ^t^Uwfid^u^T"^t
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
typeset -- kill_watch_file_id=
while getopts ':fk:h' Option; do
	case $Option in
		f)	warnOrDie='warn';									;;
		h)	usage;												;;
		k)	kill_watch_file_id=$OPTARG;							;;
		\?)	die "Invalid option: ^B-$OPTARG^b.";				;;
		\:)	die "Option ^B-$OPTARG^b requires an argument.";	;;
		*)	bad_programmer "$Option";							;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
# eval unset parameter exits function not script, so add level of indirection
function expand-origin { eval R="$1"; }
function other-origins { # {{{1
	local F O X R TAB name origin
	O=${1%/*}/ORIGINS
	[[ -f $O ]]|| return
	F=${1##*/}
	TAB='	'
	while IFS=$TAB read name origin; do
		[[ $name == $F ]]|| continue
		break
	done <$O
	[[ -n $origin ]]|| return
	expand-origin "$origin" || die "^VORIGIN^v syntax error."

	X="^VORIGIN^v^O/^o^B$name^b"
	sparkle-path "$R"
	[[ -f $R ]]||
		die "$X does not point to a file." \
			"=> ^B$origin^b" "== ^B$REPLY^b"

	WOD_ACTION="edit ^B$REPLY^b"
	warnOrDie "$X ^= $REPLY"
	REPLY=$R
	true
} # }}}1
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
	filename-from-file-w-path "$F" LOCKNAME
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
function begin-tracking { # {{{1
	$vms-track "$1" "${DESCRIPTION:=$(term-get-text descr)}"
} # }}}1
function handle-modified { #{{{1
	warnOrDie 'Checked-in and working versions differ.'
	warn "Add a checkin message for ^Bprevious^b edits."
	$vms-diff "$1" | highlight-udiff
	$vms-snap "$1"
} #}}}1
function init-or-sync-then-checkout { #{{{1
	case ${STATUS:-nope} in
		untracked)	begin-tracking "$filename";								;;
		modified)	handle-modified "$filename";							;;
		ok|ignored|untracked)	:;											;;
		nope)		warn "^T$vms-status^t does not set ^O$^o^VSTATUS^v.";	;;
		*)			warn "^T$vms-status^t: ^O$^o^VSTATUS^v=^U$STATUS^u.";	;;
	esac
	$vms-checkout "$filename"
} # }}}1
function vms-checkout-all { # {{{1
	VMSes=
	HAS_VERSMGMT=false

	versmgmt-init || {
		warn "^BVERSMGMT^b: $ERRMSG"
		return
	  }

	versmgmt-active-vmses || return

	HAS_VERSMGMT=true
	FOREACH_VMS=init-or-sync-then-checkout 
	versmgmt-apply status ./$f_name
} # }}}1
function mk-temp-copy { #{{{1
	fTEMP=/dev/null
	[[ -s $1 ]]&& fTEMP=$(mktemp)
	add-exit-actions "rm -f '$fTEMP'"
	cp "$1" "$fTEMP" || die "Could not ^Tcp $1^t."
} # }}}1
function get-ciMsg { # {{{1
	diff -u "$fTEMP" "$f_fullpath" | highlight-udiff
	ciMsg=$(term-get-text ci)
} # }}}1
function kill-watch-file-with-id { # {{{1
	[[ -z ${kill_watch_file_id:-} ]]&& return
	pkill -HUP -lf -- "^watch-file -i $kill_watch_file_id" >/dev/null 2>&1
	kill_watch_file_id=
} # }}}1
function main { # {{{1
	vms-checkout-all "$f_name"
	$HAS_VERSMGMT && mk-temp-copy "$f_fullpath"
	CKSUM_BEFORE=$(fast-crypt-hash "$f_fullpath")

	$ED "$f_fullpath"

	kill-watch-file-with-id

	CKSUM_AFTER=$(fast-crypt-hash "$f_fullpath")
	if [[ $CKSUM_BEFORE != $CKSUM_AFTER ]]; then
		trackfile "$f_fullpath"
		[[ -f .LAST_UPDATED ]]&& date -u +"$ISO_DATE" >.LAST_UPDATED

		if $HAS_VERSMGMT; then
			[[ -z ${ciMsg:-} ]]&& get-ciMsg
			versmgmt-apply snap "$f_name" "${ciMsg:-}"
		elif [[ -n $ciMsg ]]; then
			warn 'Supplied a ^Blog^b message, but there'\''s no ^IVMS^i.'
		fi
	elif [[ -n $ciMsg ]]; then
		warn 'Supplied a ^Blog^b message, but there were no changes made.'
		versmgmt-apply reshelve "$f_name"
	fi

	[[ -n ${LOCKNAME:-} ]]&& release-exclusive-lock "$LOCKNAME" $V_CACHE
} # }}}1

needs $ED
(($#))|| exec "$ED" # We don't have a file, so short circut all the rest.

needs	\
	fast-crypt-hash file-is-valid-utf8 get-exclusive-lock needs-cd		\
	needs-path release-exclusive-lock trackfile versmgmt-init warnOrDie	\
	add-exit-actions filename-from-file-w-path highlight-udiff

[[ -n ${kill_watch_file_id:-} ]]&& add-exit-actions kill-watch-file-with-id

[[ -a $1 ]]|| die "No such file ^B$1^b."
f_fullpath=$(realpath -q -- "$1") || die "Could not ^Trealpath^t ^B$1^b."
shift

other-origins				"$f_fullpath" && f_fullpath=$REPLY
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
