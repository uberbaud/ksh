#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2022-05-23,21.14.09z/2c44a1c>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^Usource files^u^]
	         Gets ^Utarget^: dependency^u information for ^Usource files^u and ^Tmake^ts
	             any targets when one of its watched dependencies changes.
	         Defaults to watching ^O*^o^T.^t^O[^o^Tch^t^O]^o
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
while getopts ':h' Option; do
	case $Option in
		h)	usage;															;;
		\?)	die USAGE "Invalid option: ^B-$OPTARG^b.";						;;
		\:)	die USAGE "Option ^B-$OPTARG^b requires an argument.";			;;
		*)	bad-programmer "No getopts action defined for ^T-$Option^t.";	;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
function init-database { # {{{1
	SQL_AUTODIE=warn
	SQL 'CREATE TEMPORARY TABLE deps (src,obj);'
	SQL 'CREATE TEMPORARY TABLE givens (src);'
	SQL 'CREATE TEMPORARY TABLE targets (obj);'
	notify "sqlite3 pid: $SQLPID"
} # }}}1
function check-files { # {{{1
	for f in "$@"; do
		needs-file -or-warn "$f" || continue
		SQLify f
		SQL "INSERT INTO givens (src) VALUES ($f);"
	done
} # }}}1
function init-dependencies { # {{{1
	local obj src deps d
	h2 "updating dependency information"
	# Without -r, `read` concats lines ending with a backslash ('\').
	SQL "SELECT DISTINCT src FROM givens WHERE src LIKE '%.c';"
	${CC:-clang} -MM -w "${sqlreply[@]}" | while read obj src deps; do
		[[ $src != *.c ]]&& continue
		obj=${obj%:}
		SQLify obj
		for d in $src $deps; do
			SQLify d
			SQL "INSERT INTO deps (src,obj) VALUES ($d,$obj);"
		done
	done
	SQL 'INSERT INTO temp.targets (obj) SELECT DISTINCT obj FROM temp.deps;'
} # }}}1
function do-make { # {{{1
	[[ ${1:?} != SIG* ]]&&
		notify "^B$1^b changed"
	SQL "SELECT obj FROM temp.targets;"
	make "${sqlreply[@]}"
} # }}}1
function signum-to-name { # {{{1
	local signame rc=${1:?}
	case $rc in
		129) signame=HUP;		rc=0;	;;
		130) signame=INT;		rc=0;	;;
		131) signame=QUIT;		rc=0;	;;
		132) signame=ILL;		rc=0;	;;
		133) signame=TRAP;		rc=0;	;;
		134) signame=ABRT;		rc=0;	;;
		135) signame=EMT;		rc=0;	;;
		136) signame=FPE;		rc=0;	;;
		137) signame=KILL;		rc=0;	;;
		138) signame=BUS;		rc=0;	;;
		139) signame=SEGV;		rc=0;	;;
		140) signame=SYS;		rc=0;	;;
		141) signame=PIPE;		rc=0;	;;
		142) signame=ALRM;		rc=0;	;;
		143) signame=TERM;		rc=0;	;;
		144) signame=URG;		rc=0;	;;
		145) signame=STOP;		rc=0;	;;
		146) signame=TSTP;		rc=0;	;;
		147) signame=CONT;		rc=0;	;;
		148) signame=CHLD;		rc=0;	;;
		149) signame=TTIN;		rc=0;	;;
		150) signame=TTOU;		rc=0;	;;
		151) signame=IO;		rc=0;	;;
		152) signame=XCPU;		rc=0;	;;
		153) signame=XFSZ;		rc=0;	;;
		154) signame=VTALRM;	rc=0;	;;
		155) signame=PROF;		rc=0;	;;
		156) signame=WINCH;		rc=0;	;;
		157) signame=INFO;		rc=0;	;;
		158) signame=USR1;		rc=0;	;;
		159) signame=USR2;		rc=0;	;;
		160) signame=THR;		rc=0;	;;
	esac
	print -r -- "${signame:-}"
	return $rc
} # }}}1
function watch-file-w-h2 { # {{{1
	SQL 'SELECT DISTINCT src FROM deps;' || { print 'SQLERROR'; return 0; }
	set -- "${sqlreply[@]}"
	h2 "watching files $*" 1>&2
	watch-file -v "$@"
	S=$(signum-to-name $?); rc=$?
	[[ -n $S ]]&& print -ru1 "SIG$S"
	return $rc
} # }}}1

needs h2 ${CC:-clang} needs-file uuid85 watch-file

(($#))|| set -- *.c
[[ $1 == \*.c ]]&&
	die "Could not find ^BC^b source code files (^O*^o^T.c^t)."

#     I'd like to use Ctrl+C (interupt) to force a regeneration of the
#  dependencies tables, but the Korn Shell (at least pdKSH), keeps
#  some behaviours even when using trap to catch the INT signal, like
#  killing the co-process, at least with SQLite, ... so we change the
#  signal that gets sent to INFO (which will still cause ksh to spit
#  out some information about watch-file, but it doesn't kill
#  sqlite3, so we're good.
#     We also stop echoing key presses since we're not reading them
#  anyway. And undo that on EXIT.
add-exit-action 'stty echo echoctl intr ^C status ^-'
stty -echo -echoctl intr ^- status ^C
trap '' INFO # ignore SIGINFO, let watch-file deal with it.

init-database
check-files "$@"
init-dependencies "$@"

# TODO: update deps without regenerating the whole thing.
while f=$(watch-file-w-h2); do
	[[ -z $f ]]&& break
	[[ -f $f || $f == SIGINFO ]]|| { print "$f"; break; }

	[[ $f == SIGINFO ]]&& warn 'Use ^BCtrl+\^b to quit'
	do-make "$f"

done; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
