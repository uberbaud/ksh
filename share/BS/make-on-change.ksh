#!/usr/local/bin/ksh93
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
	notify "sqlite3 pid: $SQLPID"
} # }}}1
function check-files { # {{{1
	for f in "$@"; do
		[[ $f == *\'* ]]&& {
			warn "The filename ^B$f^b contains a single quote and will be ignored."
			continue
	  	}
		needs-file -or-warn "$f" || continue
		SQL "INSERT INTO givens (src) VALUES ('$f');"
	done
} # }}}1
function init-dependencies { # {{{1
	local obj src deps d
	h2 "updating dependency information"
	# `mkdep` calls $CC, so lets do it directly like it does, but without
	# creating a file.
	# Without -r, `read` concats lines ending with a backslash ('\').
	SQL "SELECT DISTINCT src FROM givens WHERE src LIKE '%.c';"
	${CC:-clang} -MM -w "${sqlreply[@]}" | while read obj src deps; do
		[[ $src == *.h ]]&& continue
		obj=${obj%:}
		for d in $src $deps; do
			SQL "INSERT INTO deps (src,obj) VALUES ('$d','$obj');"
		done
	done
} # }}}1
function regenerate-dependencies { # {{{1
	NOT-IMPLEMENTED
} # }}}1
function watch-file-w-h2 { # {{{1
	SQL 'SELECT DISTINCT src FROM deps;' || {
		print -ru1 -- 'SQLERROR'
		return 0
	  }
	set -- "${sqlreply[@]}"
	h2 "watching files $*" 1>&2
	watch-file -v "$@"; rc=$?
	(($rc==130))&& { print -ru1 -- 'SIGINT'; rc=0; }
	return $rc
} # }}}1

needs h2 ${CC:-clang} needs-file uuid85 watch-file

(($#))|| set -- *.[ch]
[[ $1 == \*.\[ch\] ]]&&
	die "Could not find files matching ^O*^o^T.^t^O[^o^Tch^t^O]^o."

add-exit-action 'stty sane'
stty -echo -echoctl

init-database
check-files "$@"
init-dependencies "$@"

# TODO: update deps without regenerating the whole thing.
while f=$(watch-file-w-h2); do
	[[ -z $f ]]&& break
	[[ $f == SQLERROR ]]&& break
	[[ $f == SIGINT ]]&& {
		warn 'Use ^BCtrl+\^b to quit'
		regenerate-dependencies
		continue
	  }
	print -r -- "$f changed"
	SQL "SELECT DISTINCT obj FROM deps WHERE src = '$f';"
	for o in "${sqlreply[@]}"; do
		h2 "making $o"
		make "$o"
	done
done; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
