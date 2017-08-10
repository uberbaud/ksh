#!/bin/ksh
# @(#)[:&>|IvruXm6Dc^Ah(>olM: 2017/08/03 14:05:13 tw@csongor.lan]
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

: ${KSH_VERSION:?Run from with KSH}

# Usage {{{1
full_pgm_path="$(readlink -nf "$0")"
: ${full_pgm_path:?}
this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t ^[^Uuser^u^T@^t^]^Uhost^u^T:^t^Uremote dir^u ^Ulocal dir^u
	         Sync two directories over ssh
	           ^Ulocal dir^u defaults to \$PWD
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
		"  No getopts action defined for [1m-$1[22m."
  };	# }}}2
i_am_the_local=true
i_am_the_remote=false
while getopts ':hR:' Option; do
	case $Option in
		R)	LOGFILE="$HOME/log/synrdir-$OPTARG"
			i_am_the_local=false
			i_am_the_remote=true
			;;
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

DIR_IS_SET=false

tmfmt='%Y-%m-%dT%H:%M:%S%z'
statfmt='%m %Op %z'

alias fail='{ print fail; return 1; }'
alias okay='{ print okay; return 0; }'
alias require_dir_be_set='$DIR_IS_SET || { print dirunset; return 1; }'
function l-getfile { # {{{1
	print -pr i-wantfile "$1"
	local status modtm perm size
	read -pr status modtm perm size
	[[ $status == sending ]]&& {
		dd of="$1" bs=$size count=1 status=none <&p
		touch -md "$(date -ur $modtm +'%Y-%m-%dT%H:%M:%SZ')" "./$1" 
		chmod ${perm#??} "./$1"
		chflags uchg "./$1"
		read -pr status
		[[ $status == okay ]]|| return 1
		return 0
	}
} # }}}1
function r-pushfile { # {{{1
	require_dir_be_set
	set -A statfo $(stat -qf "$statfmt" -- "$1") || fail
	print sending "${statfo[@]}"
	dd if="$1" bs="${statfo[2]}" count=1 status=none
	okay
} # }}}1
function r-setdir { # {{{1
	cd "$1" || fail
	DIR_IS_SET=true
	okay
} # }}}1
function l-putfile { # {{{1
	print -p u-wantfile "$1"
	read -pr status
	[[ $status == okay ]]|| quit
	set -A statfo $(stat -qf "$statfmt" -- "$1") || quit
	print -p sending "${statfo[@]}"
	read -pr status
	[[ $status == go ]]|| quit
	dd if="$1" bs="${statfo[2]}" count=1 status=none >&p
	print -p done
	read -pr status
} #}}}1
function r-pullfile { # {{{1
	require_dir_be_set
	print okay
	local status modtm perm size
	read -r status modtm perm size
	r-log $stats "$modtm $perm $size"
	[[ $status == sending ]]&& {
		print go
		dd of="$1" bs=$size count=1 status=none
		touch -md "$(date -ur $modtm +'%Y-%m-%dT%H:%M:%SZ')" "./$1"
		chmod ${perm#??} "./$1"
		chflags uchg "./$1"
		read -r status
		[[ $status == done ]]|| fail
		okay
	  }
	fail
} # }}}1
function r-listfiles { # {{{1
	require_dir_be_set
	local i=0 filelist
	for f in *; do
		[[ $f == r.log ]]&& continue
		[[ -h $f ]]&& continue
		[[ -f $f ]]|| continue
		[[ -s $f ]]|| continue
		filelist[$((i++))]="$f"
	done
	((i))|| { print 'empty'; return 0; }
	print listing $i files
	printf '%s\n' "${filelist[@]}"
	okay
} # }}}1
function r-log { # {{{1
		printf '      cmd> %s\n' "$1"
		printf '  arglist> %s\n' "$2"
} >>"$LOGFILE"
function s-quit { # {{{1
	print $status
	print -p quit
	read -pr status; print $status
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
		printf '\e[s ==> Gather passphrase\n'
		# force an x-window
		ssh-add < /dev/null
		# restore cursor and blank intermediate
		printf '\e[u\e[K\e[0J'
	  }
	ssh-add -l >/dev/null || die 'Bad passphrase or such.'
	scp "$full_pgm_path" $1:"bin/$this_pgm" ||
		die "Could not install current version of ^B$this_pgm^b."
	ssh "$1" "bin/$this_pgm -R '$HOSTNAME'" |&
} # }}}1


$i_am_the_remote && { # {{{1
	read -r greeting
	[[ $greeting == hello ]]|| exit 1
	print ready
	while read -r cmd arglist; do
		r-log "$cmd" "$arglist"
		case $cmd in
			setdir)		r-setdir "$arglist";			;;
			listfiles)	r-listfiles;					;;
			i-wantfile)	r-pushfile "$arglist";			;;
			u-wantfile)	r-pullfile "$arglist";			;;
			quit)		print 'quitting'; break;		;;
		esac
	done
	# any clean-up
	exit 0
} # }}}1

temppath=''; rlst=''; llst='';
$i_am_the_local && { # {{{1

	: ${FPATH:?Run from within KSH}
	needs ssh-add scp ssh

	(($#))||	die 'Missing required argument [4mhost:path[24m.'
	(($#>2))&&	die 'Unexpected arguments.'
	[[ $1 == *:* ]]||
		die 'Missing [4mhost[24m or [4mremote directory[24m (no colon in arg1).'

	remote_host="${1%%:*}"
	remote_dir="${1#*:}"
	cd "${2:-$PWD}" || die "Could not cd to [1mcd[22m [1m$local_dir[22m."

	tmppath="$(mktemp -d)"
	trap 'l-cleanup' EXIT

	rlst=$tmppath/r.lst
	llst=$tmppath/l.lst

	fileagent "$remote_host"

	print -pr hello
	read -pr status; print $status
	[[ $status == ready ]]|| { kill %1; exit 1; }

	print -pr setdir $remote_dir
	read -pr status; print $status

	print -pr listfiles
	read -pr status filecount files
	if [[ $status == empty ]]; then
		: >"$rlst"
	else
		[[ $status == listing && $files == files ]]|| s-quit
		while ((filecount--)); do
			read -pr filename
			printf '%s\n' "$filename"
		done | sort >$rlst
		read -pr status
		[[ $status == okay ]]|| s-quit
	fi

	# get local list
	for f in *; do
		[[ -h $f ]]&& continue
		[[ -f $f ]]|| continue
		[[ -s $f ]]|| continue
		printf '%s\n' "$f"
	done | sort >$llst


	# get files on remote but missing on local
	splitstr NL "$(comm -13 "$llst" "$rlst")" filequeue
	for rf in "${filequeue[@]}"; do
		print getting "<$rf>"
		l-getfile "$rf" || s-quit
	done

	# send files on local but missing on remote
	splitstr NL "$(comm -23 "$llst" "$rlst")" filequeue
	for lf in "${filequeue[@]}"; do
		print putting "<$lf>"
		l-putfile "$lf" || s-quit
	done

	s-quit
} # }}}1

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
