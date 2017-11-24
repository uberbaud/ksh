#!/bin/ksh
# @(#)[:Vxjh}I8JZBb4lsX^GSh{: 2017-08-08 01:31:02 Z tw@csongor]
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t ^Ufile^u ^[^Ufile2 ...^u^]
	         Open files with an appropriate app.
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
while getopts ':h' Option; do
	case $Option in
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
function warnOrDie { #{{{1
	case $warnOrDie in
		die)  die "$@" 'Use [1m-f22m to force an edit.';		;;
		warn) warn "$@";											;;
		*)    die '[1mProgrammer error[22m:' \
					'warnOrDie is [1m${warnOrDie}[22m.';		;;
	esac
} # }}}1

needs file

sysdata=${XDG_DATA_HOME:?}/sysdata
[[ -f $sysdata/mime.types ]]||    die 'Missing ^B$sysdata/mime.types^b'
[[ -f $sysdata/mime.handlers ]]|| die 'Missing ^B$sysdata/mime.handlers^b'

function get-filetype-from-ext { # {{{1
	gsub '/' '\/' "$1"
	typeset -l e="$REPLY"
	REPLY="$(awk -F'\t' "/^$e\t/ {print \$2}" $sysdata/mime.types)"
} # }}}1
function get-handler-for-filetype { # {{{1
	gsub '/' '\/' "$1"
	local ft="$REPLY"
	REPLY="$(awk -F'\t' "/^$ft\t/ {print \$2}" $sysdata/mime.handlers)"
} # }}}1
function exec-handler { # {{{1
	local handler="$1" arg="$2"
	[[ $handler == *%f ]]&& {
		arg="$(readlink -nf $arg)"
		gsub %f %s "$handler"
		handler="$REPLY"
	  }
	gsub '\' '\\' "$REPLY"
	gsub '"' '\"' "$handler"
	eval "cmd=\"$REPLY\""
	gsub \' "'\\''" "$arg"
	gsub '%s' "'$REPLY'" "$cmd"
	eval "set -- $REPLY"
	nohup "$@" </dev/null >>$HOME/log/open 2>&1 &
} # }}}1
function open-one-file { # {{{1
	REPLY=''
	local file='' is_remote=false filetype='' filehandler='' url=''
	if [[ $1 == https://* ]]; then
		is_remote=true
		file="$1"
	else
		file="$(readlink -nf "$1" 2>/dev/null)"
		desparkle "$file"
		[[ -n $file ]]|| { warn "^B$REPLY^b: No such path."; return 1; }
		[[ -a $file ]]|| { warn "^B$REPLY^b: No such file."; return 1; }
		[[ -f $file ]]|| { warn "^B$REPLY^b: Not a file.";   return 1; }
	fi

	typeset -l F
	if $is_remote; then
		REPLY='remote/web'
	elif [[ $F == readme.m@(d|arkdown) ]]; then
		REPLY='text/markdown'
	elif [[ $F == read* ]]; then
		REPLY='text/plain'
	elif [[ $F == license* ]]; then
		REPLY='text/plain'
	elif [[ $F == install* ]]; then
		REPLY='text/plain'
	else
		get-filetype-from-ext "${F%%*.}"
	fi

	if [[ -n $REPLY ]]; then
		filetype="$REPLY"
	else
		filetype="$(file -bi "$file")"
	fi

	get-handler-for-filetype "$filetype"
	if [[ -n $REPLY ]]; then
		filehandler="$REPLY"
	else
		warn "No handler for ^B$filetype^b."
		return 1
	fi

	if $is_remote; then
		url="${file#http*://}"; url="${url%\?*}"
	else
		desparkle "${file##*/}"
		url="$REPLY"
	fi

	local n1 n2
	n1="opening ^B$url^b (^S$filetype^s)"
	n2="with ^T$filehandler^t."

	if ((COLUMNS<${#n1}+1+${#n2})); then
		notify "$n1" "    $n2"
	else
		notify "$n1 $n2"
	fi
	exec-handler "$filehandler" "$file" ||
		warn "Could not open ^B$file^b."
} # }}}1

for f; do open-one-file "$f"; done

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
