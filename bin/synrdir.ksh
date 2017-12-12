#!/bin/ksh
# @(#)[:&>|IvruXm6Dc^Ah(>olM: 2017/08/03 14:05:13 tw@csongor.lan]
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset; : ${KSH_VERSION:?Run from with KSH}

# Usage {{{1
full_pgm_path="$(readlink -nf "$0")"
: ${full_pgm_path:?}
this_pgm="${0##*/}"
LOGLEVELS='^Bnone^b, ^Bnormal^b, or ^Ball^b.'
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t ^[-L ^Uloglevel^u^] ^[^Uuser^u^T@^t^]^Uhost^u^T:^t^Uremote dir^u ^Ulocal dir^u
	         Sync two directories over ssh
	           ^Ulocal dir^u defaults to \$PWD
	         ^T-L^t ^Uloglevel^u
	             Where loglevel is one of
	               ^Bnone^b (no output),
	               ^Bnormal^b (show ^Igetting^i and ^Iputting^i files, or
	               ^Ball^b (show pretty much the whole convo).
	             The default is ^Inormal^i
	       ^T${PGM} -R^t ^Uotherhost^u
	         Start as the remote
	           ^BNever call this directly.^b The local version does this.
	       ^T${PGM} -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
function bad_programmer {	# {{{2
	die 'Programmer error:'	\
		"  No getopts action defined for ^B-$1^b."
  };	# }}}2
i_am_the_local=true
i_am_the_remote=false
integer LOGNONE=-1 LOGNORM=0 LOGDBUG=1
VERBOSITY_LEVEL=$LOGNORM
while getopts ':hR:L:' Option; do
	case $Option in
		R)	LOGFILE="$HOME/log/synrdir-$OPTARG"
			i_am_the_local=false
			i_am_the_remote=true
			;;
		L)
			case $OPTARG in
				none)	VERBOSITY_LEVEL=$LOGNONE;	;;
				normal)	VERBOSITY_LEVEL=$LOGNORM;	;;
				all)	VERBOSITY_LEVEL=$LOGDBUG;	;;
				*)	die "Bad ^Ulog level^u, expected one of $LOGLEVELS"; ;;
			esac
			;;
		h)	usage;												;;
		\?)	die "Invalid option: ^B-$OPTARG^b.";				;;
		\:)	die "Option ^B-$OPTARG^b requires an argument.";	;;
		*)	bad_programmer "$Option";							;;
	esac
done
case $VERBOSITY_LEVEL in
	$LOGNONE) LOG_PRINTER=:;				;;
	$LOGNORM) LOG_PRINTER=l-log-normal;		;;
	$LOGDBUG) LOG_PRINTER=l-log-all;		;;
	*)	die "Unexpectedly impossible VERBOSITY_LEVEL: $VERBOSITY_LEVEL"
		;;
esac
# remove already processed arguments
shift $(($OPTIND - 1))
# ready to process non '-' prefixed arguments
# /options }}}1

MYNAME="$(readlink -fn "$0")"
CKSUM="$(cksum -qa sha384b "$MYNAME")"
DIR_IS_SET=false

tmfmt='%Y-%m-%dT%H:%M:%S%z'
statfmt='%m %Op %z %Df'
statvars='modtm perm size flags'

alias r-fail='{ r-reply fail; return 1; }'
alias r-okay='{ r-reply okay; return 0; }'
alias require_dir_be_set='$DIR_IS_SET || { r-reply dirunset; return 1; }'
alias l-log="$LOG_PRINTER"

function l-log-normal { # {{{1
	(($1>$VERBOSITY_LEVEL))&& return
	shift
	print "  $*"
} # }}}1
function l-log-all { # {{{1
	shift
	notify "$@"
} # }}}1
function r-log { # {{{1
	typeset -L12 REQ="$1"
	print -u3 "$REQ: $2"
} # }}}1
function l-request { #{{{1
	l-log $LOGDBUG "request: ^[$*^]"
	print -pr -- "$@"
} # }}}1
function l-reply-is { # {{{1
	local expected="$1"; shift
	[[ ${1:-} == WITH-VARS ]]&& shift
	read -pr status "$@"
	l-log $LOGDBUG "got: $status, expected: $expected"
	[[ $expected == ANY || $status == $expected ]]
} # }}}1
function r-reply { # {{{1
	r-log reply "$*"
	print -r -- "$@"
} # }}}1
function r-request-is { # {{{1
	local request expected="$1"; shift
	[[ ${1:-} == WITH-VARS ]]&& shift
	read -r request "$@"
	r-log request "got: $request, expected: $expected"
	[[ $expected == ANY || $request == $expected ]]
} # }}}1
function fflags-to-flagstr {
	((0xffff0000&$1))&& warn 'system flags not settable.'
	((0x0000fff0&$1))&& warn 'unsettable or unknown flags.'
	case $((0x000f&$1)) in
		0)	flagstr='';					;;
		1)	flagstr=nodump;				;;
		2)	flagstr=uchg;				;;
		3)	flagstr=nodump,uchg;		;;
		4)	flagstr=uappnd;				;;
		5)	flagstr=nodump,uappnd;		;;
		6)	flagstr=uchg,uappnd;		;;
		7)	flagstr=nodump,uchg,uappnd;	;;
	esac
}
function l-getfile { # {{{1
	l-request i-wantfile "$1"
	local status $statvars flagstr
	l-reply-is sending WITH-VARS $statvars && {
		dd of="$1" count=$size bs=1 status=none <&p
		touch -md "$(date -ur $modtm +'%Y-%m-%dT%H:%M:%SZ')" "./$1" 
		chmod ${perm#??} "./$1"
		fflags-to-flagstr $flags
		chflags $flagstr "./$1"
		l-reply-is okay || return 1
		return 0
	}
} # }}}1
function r-pushfile { # {{{1
	require_dir_be_set
	set -A statfo $(stat -qf "$statfmt" -- "$1") || r-fail
	r-reply sending "${statfo[@]}"
	dd if="$1" count="${statfo[2]}" bs=1 status=none
	r-okay
} # }}}1
function r-setdir { # {{{1
	cd "$1" || r-fail
	DIR_IS_SET=true
	r-okay
} # }}}1
function l-putfile { # {{{1
	l-request u-wantfile "$1"
	l-reply-is okay || l-quit
	set -A statfo $(stat -qf "$statfmt" -- "$1") || l-quit
	l-request sending "${statfo[@]}"
	l-reply-is go || l-quit
	dd if="$1" count="${statfo[2]}" bs=1 status=none >&p
	l-request done
	l-reply-is okay
} #}}}1
function r-pullfile { # {{{1
	require_dir_be_set
	r-reply okay
	local status $statvars
	r-request-is sending WITH-VARS $statvars && {
		r-reply go
		dd of="$1" count=$size bs=1 status=none
		touch -md "$(date -ur $modtm +'%Y-%m-%dT%H:%M:%SZ')" "./$1"
		chmod ${perm#??} "./$1"
		fflags-to-flagstr $flags
		chflags $flagstr "./$1"
		r-request-is done || r-fail
		r-okay
	  }
	r-fail
} # }}}1
function r-listfiles { # {{{1
	require_dir_be_set
	local i=0 filelist F
	for f in *; do
		[[ $f == r.log ]]&& continue
		[[ -h $f ]]&& continue
		[[ -f $f ]]|| continue
		[[ -s $f ]]|| continue
		filelist[$((i++))]="$f"
	done
	((i))|| { r-reply 'empty'; return 0; }
	r-reply listing $i files
	for F in "${filelist[@]}"; { print "$F"; }
	r-okay
} # }}}1
function l-quit { # {{{1
	(($?))&& notify "remote status: $status"
	l-request quit
	l-reply-is quitting
	exit 0
} # }}}1
function l-cleanup { # {{{1
	[[ -n $temppath ]]&& {
		[[ -f $rlst ]]&& rm "$rlst"
		[[ -f $llst ]]&& rm "$llst"
		rmdir "$temppath"
	}
} # }}}1
function fileagent { # {{{1
	ssh-add -l >/dev/null || {
		# hide cursor, plus
		print '\033[s ==> Gather passphrase'
		# force an x-window
		ssh-add < /dev/null
		# restore cursor and blank intermediate
		print -n '\033[u\033[K\033[0J'
	  }
	ssh-add -l >/dev/null || die 'Bad passphrase or such.'
	ssh "$1" "bin/$this_pgm -R '$HOSTNAME'" |&
} # }}}1

$i_am_the_remote && { # {{{1
	exec 3>"$LOGFILE"
	r-request-is hello || exit 1
	r-reply ready

	r-request-is cksum || r-fail
	r-reply cksum "$CKSUM"

	while read -r cmd arglist; do
		r-log "$cmd" "$arglist"
		case $cmd in
			setdir)		r-setdir "$arglist";			;;
			listfiles)	r-listfiles;					;;
			i-wantfile)	r-pushfile "$arglist";			;;
			u-wantfile)	r-pullfile "$arglist";			;;
			quit)		r-reply 'quitting'; break;		;;
		esac
	done
	# any clean-up
	exit 0
} # }}}1

temppath=''; rlst=''; llst='';
$i_am_the_local && { # {{{1

	: ${FPATH:?Run from within KSH}
	needs ssh-add scp ssh

	(($#))||	die 'Missing required argument ^Uhost:path^u.'
	(($#>2))&&	die 'Unexpected arguments.'
	[[ $1 == *:* ]]||
		die 'Missing ^Uhost^u or ^Uremote directory^u (no colon in arg1).'

	remote_host="${1%%:*}"
	remote_dir="${1#*:}"
	host $remote_host >/dev/null ||
		die "Cannot connect to ^B$remote_host^b."
	cd "${2:-$PWD}" ||
		die "Could not cd to ^Tcd^t ^B$local_dir^b."

	tmppath="$(mktemp -d)"
	trap 'l-cleanup' EXIT

	rlst=$tmppath/r.lst
	llst=$tmppath/l.lst

	fileagent "$remote_host"

	l-request hello
	l-reply-is ready || { kill %1; exit 1; }

	msg_neednew="Try ^Tscp^t ^U$full_pgm_path^u ^U$remote_host^u:^Ubin/$this_pgm^u"
	l-request cksum
	l-reply-is cksum WITH-VARS rcksum || {
		kill %1
		die "Remote doesn't understand ^Bcksum^b." "$msg_neednew"
	  }
	[[ $rcksum == "$CKSUM" ]]|| {
		kill %1
		die "Checksums do not match" "$msg_neednew"
	  }

	l-request setdir $remote_dir
	l-reply-is okay || l-quit

	l-request listfiles
	l-reply-is ANY WITH-VARS filecount files
	if [[ $status == empty ]]; then
		: >"$rlst"
	else
		[[ $status == listing && $files == files ]]|| l-quit
		while ((filecount--)); do
			read -pr -- filename
			print -- "$filename"
		done | sort >$rlst
		l-reply-is okay || l-quit
	fi

	# get local list
	for f in *; do
		[[ -h $f ]]&& continue
		[[ -f $f ]]|| continue
		[[ -s $f ]]|| continue
		print -- "$f"
	done | sort >$llst

	# get files on remote but missing on local
	splitstr NL "$(comm -13 "$llst" "$rlst")" filequeue
	if (set +u; ((${#filequeue[*]}))); then
		for rf in "${filequeue[@]}"; do
			l-log $LOGNORM "getting <$rf>"
			l-getfile "$rf" || l-quit
		done
	fi

	# send files on local but missing on remote
	splitstr NL "$(comm -23 "$llst" "$rlst")" filequeue
	if (set +u; ((${#filequeue[*]}))); then
		for lf in "${filequeue[@]}"; do
			l-log $LOGNORM "putting <$lf>"
			l-putfile "$lf" || l-quit
		done
	fi

	l-quit
} # }}}1

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
