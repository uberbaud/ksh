#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2023-01-04,03.05.19z/21ab967>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

set -A CMDLIST -- changed changelog checkout diff snap status track vmslist
set -A ALTLIST -- cmdlist help

CMD=
this_pgm=${0##*/}
function help { # {{{1
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^Ucmd^u ^Ufile^u ^U…^u
	         Generalized opaque wrapper around various version/revision
	         management systems (^IVMS^i).
	           ^Tchanged^t ^Ufile^u
	               Silently compares latest ^Tsnap^tped revision, or ^Urev^u
	               with ^Ufile^u, returning an exit code of ^T0^t if they are the
	               same and ^T1^t if they differ. If ^Ufile^u is in a directory
	               which is managed by a ^IVMS^i
	           ^Tchangelog^t
	               List changed files with consolidated log messages.
	           ^Tcheckout^t ^Ufile^u ^[^Urev^u^]
	               Gets the latest revision, or ^Urev^u, of a file from the archive 
	               and sets locks. In most ^IVMS^ies (e.g. ^Tgit^t) this is a ^Ino-op^i.
	           ^Tcmdlist^t
	               ^GSee^g ^T-c^t
	           ^Tdiff^t ^Ufile^u ^[^Urev^u^]
	               Diffs latest ^Tsnap^tped revision, or ^Urev^u with ^Ufile^u
	           ^Thelp^t
	               ^GSee^g ^T-h^t
	           ^Tsnap^t ^Ufile^u ^Umsg^u
	               Adds a new revision to the archive with log ^Umsg^u and
	               removes any locks. In systems like ^Tgit^t, the log message
	               will be saved outside of the ^IVMS^i.
	           ^Tstatus^t ^[^[^Upath^u/^]^Ufile^u^|^Upath^u^]
	               Reports ^IVMS^ies which manage the given or current ^Upath^u,
	               and ^Tnew^t, ^Tmodified^t, or ^Tignored^t for each if ^Ufile^u
	               is given.
	           ^Ttrack^t ^Ufile^u ^Udescription^u
	               Begins tracking a file and sets its ^Udescription^u.
	           ^Tvmslist^t
	               ^GSee^g ^T-l^t
	       ^T$PGM -l^t^|^T--list^t^|^Tvmslist^t
	         Lists to stdout version/revision management systems
	         handled by ^T$PGM^t.
	       ^T$PGM -c^t^|^T--commands^t^|^Tcmdlist^t
	         Lists to stdout all ^T$this_pgm^t commands.
	       ^T$PGM -h^t^|^T--help^t^|^Thelp^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
function cmdlist { #{{{1
	local c
	set -s -- "${CMDLIST[@]}" "${ALTLIST[@]}"
	for c { print -r "$c"; }
} # }}}1
function vmslist { # {{{1
	print -r -- "${VERSMGMT_AVAILABLE:-}"
} # }}}1
function CMD-is-valid { # {{{1
	local valid
	for valid in "${CMDLIST[@]}"; do
		[[ $CMD == $valid ]]&& return
	done
	false
} # }}}1
function prn_status { # {{{1
	print "$vms: ${STATUS:?}"
} # }}}1
# process -options {{{1
while [[ $# -gt 0 && $1 == -* ]]; do
	case $1 in
		-h|--help)		CMD=help;					;;
		-l|--list)		CMD=vmslist;				;;
		-c|--commands)	CMD=cmdlist;				;;
		*)	die USAGE "Unknown flag: ^B$1^b.";		;;
	esac
	shift
done
# /options }}}1

needs die sparkle versmgmt-init highlight-udiff

[[ -z $CMD && $# -eq 0 ]]&& die "Missing required ^Ucommand^u."
[[ -n $CMD ]]|| { CMD=$1; shift; }

[[ $CMD == @(cmdlist|help) ]]&& { $CMD; exit; }

CMD-is-valid || die "Unknown ^Ucommand^u ^B$CMD^b."

versmgmt-init ||
	die "^Tversmgmt-init^t failed." 						\
		"Generalized version managment is not available."	\
		${ERRMSG:+"$ERRMSG"}

[[ $CMD == vmslist ]]&& { $CMD; exit; }

### HANDLE Path/FileName ARG
FILEARG=$(realpath -q ${1:-.}) || die "^B$1^b does not exit."
(($#))&& shift
WORKPATH=$FILEARG
[[ -f $WORKPATH ]]&& WORKPATH=${WORKPATH%/*}
FILENAME=${FILEARG#"$WORKPATH"}
FILENAME=${FILENAME#/}
needs-cd -or-die "$WORKPATH"

### GET APPLICABLE VERSION MANAGERS
versmgmt-active-vmses

### ALLOWED COMMANDS WITH NEITHER A FILE ARG NOR ANY VMS
[[ $CMD == status && -z ${FILENAME-} ]]&& {
	print -r -- "vmses: ${VMSes:--none-}"
	exit
  }

### ALL COMMANDS THAT MAKE IT HERE REQUIRE A VMS
[[ -n ${VMSes:-} ]]|| die "No active vmses for ^N$WORKPATH^n."

[[ $CMD == changelog && -z ${FILENAME-} ]]&& {
	versmgmt-apply "$CMD"
	exit
  }

### ALL COMMANDS THAT MAKE IT TO HERE REQURE A FILE ARG.
[[ -n ${FILENAME-} ]]|| die "^T$CMD^t requires a file argument."
needs-file -or-die "$WORKPATH/$FILENAME"

### SPECIAL HANDLING FOR COMMAND: status
[[ $CMD == status ]]&& FOREACH_VMS=prn_status
STATUS=-0-

### DO THE THINGS
set -- versmgmt-apply "$CMD" "$FILENAME" "$@"
if [[ $CMD == diff ]]; then
	"$@" | highlight-udiff
else
	"$@"
fi; exit

# Copyright (C) 2023 by Tom Davis <tom@greyshirt.net>.
