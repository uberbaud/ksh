#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2021-11-22,16.46.01z/112d8e4>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset

PGM=${0##*/}
LOG=${HOME:?}/log/${PGM%.ksh}.log
LOCAL_BASE=$HOME/local
XDG_DATA_HOME=${XDG_DATA_HOME:-$LOCAL_BASE/share}
XDG_CACHE_HOME=${XDG_CACHE_HOME:-$LOCAL_BASE/cache}			#!!!
DOCSTORE=$HOME/hold/DOCSTORE								#!!!
TMPDIR=${TMPDIR:-$XDG_CACHE_HOME/temp}; export TMPDIR		#!!!
AMUSE_DATA_HOME=${AMUSE_DATA_HOME:-$XDG_DATA_HOME/amuse}	#!!!

USRDB=$XDG_CACHE_HOME/locate.db
TRAPSIGS='EXIT HUP INT QUIT TRAP BUS TERM'
NL='
' # ^ <- capture a newline

function fullstop { # {{{1
	local wantshift=true
	case $1 in
		OK)          errno=0;		;; # successful termination
		USAGE)       errno=64;		;; # command line usage error
		DATAERR)     errno=65;		;; # data format error
		NOINPUT)     errno=66;		;; # cannot open input
		NOUSER)      errno=67;		;; # addressee unknown
		NOHOST)      errno=68;		;; # host name unknown
		UNAVAILABLE) errno=69;		;; # service unavailable
		SOFTWARE)    errno=70;		;; # internal software error
		OSERR)       errno=71;		;; # system error (e.g., can't fork)
		OSFILE)      errno=72;		;; # critical OS file missing
		CANTCREAT)   errno=73;		;; # can't create (user) output file
		IOERR)       errno=74;		;; # input/output error
		TEMPFAIL)    errno=75;		;; # temp failure; might succeed on retry
		PROTOCOL)    errno=76;		;; # remote error in protocol
		NOPERM)      errno=77;		;; # permission denied
		CONFIG)      errno=78;		;; # configuration error
		*)  print -ru2 'BAD PROGRAMMER: BAD errtype on fullstop.'
			wantshift=false
			;;
	esac
	$wantshift && shift
	print -ru2 -- "FAILED: $1"; shift
	for msgln { print -ru2 -- "        $1"; }
	exit ${errno:-1}
} # }}}1
function show-usage { # USAGE on any args {{{1
	print -ru2 -- 			\
		"Usage: $PGM$NL"	\
		'         Make our own locate.db so we can see our non-public stuff.'
} # }}}1
function mk-locate-db { # {{{1
	2>/dev/null find							\
		${HOME:-}								\
		-name RCS					-prune -or	\
		-path ${XDG_CACHE_HOME:?}	-prune -or	\
		-path ${TMPDIR:?}			-prune -or	\
		-path ${AMUSE_DATA_HOME:?}	-prune -or	\
		-path ${DOCSTORE:?}			-prune -or	\
		-print									\
	| /usr/libexec/locate.mklocatedb
} # }}}1
function main { # {{{1
	local fsize

	umask 077 # protect, just in case

	ftmp=$(mktemp -t locatedb-XXXXXXXXX) ||
		fullstop CANTCREAT 'Could not `mktemp`'
	trap "rm '$ftmp'" $TRAPSIGS

	mk-locate-db >>"$ftmp" ||
		fullstop CANTCREAT "\`mk-locate-db\` was not successful (rc $?)."

	# 257 size comes from /usr/libexec/locate.updatedb
	fsize=$(stat -f%z "$ftmp")
	((fsize<=257)) &&
		fullstop CANTCREAT "locate database was empty."

	mv -f "$ftmp" "$USRDB" ||
		fullstop UNAVAILABLE "Could not \`mv '$ftmp' '$USRDB'\`."

	trap - $TRAPSIGS

} # }}}1

(($#))&& { show-usage; fullstop USAGE 'Did not expect any arguments.'; }

[[ -d ${LOG%/*} ]]|| mkdir -p "${LOG%/*}" ||
	fullstop CANTCREAT 'Could not `mkdir` log path'
exec 1>$LOG 2>&1 ||
	fullstop UNAVAILABLE "Could not redirect output to $LOG."

# test for id == root
[[ $(id -u) -eq 0 ]]&& fullstop CONFIG 'May NOT be run as ROOT.'

# ensure USRDB's directory exists before we try to create a file there.
[[ -d ${USRDB%/*} ]]|| mkdir -p "${USRDB%/*}" ||
	fullstop CANTCREAT 'Could not `mkdir` locate.db path'

# ... and is writable
[[ -w ${USRDB%/*} ]]||
	fullstop NOPERM "'${USRDB%/*}' (locate.db path) is not writable by you."

# Get the home directory for the particular user, to overcome an issue
# when run as another user.
spath=$(getent passwd $(id -un)|awk -F: '{print $6}') ||
	fullstop UNAVAILABLE 'Could not get user home (1).'

# ... make sure we got something
[[ -n $spath ]]||
	fullstop UNAVAILABLE 'Could not get user home (2).'

# ... and that it's a directory
[[ -d $spath ]]||
	fullstop UNAVAILABLE "$spath is not a directory."

# keep the following on a single line to prevent confusing ksh if we
# edit/change the file while it is being run.
main "$@"; exit

# Copyright (C) 2021 by Tom Davis <tom@greyshirt.net>.
