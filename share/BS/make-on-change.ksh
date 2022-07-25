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
	SQL 'CREATE TEMPORARY TABLE files (name,ext,type);'

	SQL 'CREATE TEMPORARY TABLE deps (src,obj);'
	SQL 'CREATE TEMPORARY TABLE givens (src);'
	SQL 'CREATE TEMPORARY TABLE targets (obj);'
	notify "sqlite3 pid: $SQLPID"
} # }}}1
function check-files { # {{{1
	local f o c ext
	for f in "$@"; do
		needs-file -or-warn "$f" || continue
		ext=${f##*.}
		SQLify f ext
		SQL "INSERT INTO givens (src) VALUES ($f);"
		SQL "INSERT INTO files (name,ext,type) VALUES ($f,$ext,'G');"
	done
	SQL "SELECT name FROM files WHERE name LIKE '%.o';"
	for o in "${sqlreply[@]}"; do
		c=${o%.o}.c
		if [[ -f $c ]]; then
			SQLify c
			SQL "INSERT INTO files (name,ext,type) VALUES ($c,'c','C');"
		elif [[ -f ${p:+"$p"/}../$f ]]; then
			f=$(realpath -q -- "${p:+"$p"/}../$f")
			f=$(relative-to-pwd "$f")
		fi
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
	local msg extra
	if [[ ${1:?} == SIG* ]]; then
		msg='^WSignal received^w'
		extra='^WUse^w ^BCtrl^b^G+^g^B\^b ^Wto quit.^w'
	else
		msg="^B$1^b changed"
	fi
	notify "$msg, running ^Tmake^t." ${extra:+"$extra"}
	SQL "SELECT obj FROM temp.targets;"
	make "${sqlreply[@]}"
} # }}}1
function report-changed-sources { # {{{1
	SQL 'SELECT DISTINCT src FROM deps;' || { print 'SQLERROR'; return 0; }
	set -- "${sqlreply[@]}"
	h3 "watching files $*" 1>&2
	watch-file -v "$@"
	S=$(signum-to-name $?); rc=$?
	[[ -n $S ]]&& print -ru1 "SIG$S"
	return $rc
} # }}}1

needs h2 h3 ${CC:-clang} needs-file signum-to-name uuid85 watch-file

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
trap '' INFO QUIT # ignore SIGINFO and SIGQUIT, let watch-file deal with it.

# TODO: USE `$make_or_build` instead of hard coding `make` #
make_or_build=build
[[ -f makefile || -f Makefile ]]&&
	make_or_build=make

init-database
check-files "$@"
init-dependencies "$@"

# TODO: update deps without regenerating the whole thing.
while f=$(report-changed-sources); do
	[[ -z $f || $f == SIGQUIT ]]&& break;
	[[ -f $f || $f == SIGINFO ]]|| { print "$f"; break; }

	do-make "$f"
done; exit 0

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
