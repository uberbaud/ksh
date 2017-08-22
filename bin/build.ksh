#!/bin/ksh
# @(#)[:F;d=rN-VG?4R1`?E!Lt_: 2017-08-21 20:07:11 Z tw@csongor]
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t
	         Uses information in a header to get build options, then does the build.
	         ^T-v^t  verbose.
	         ^T-n^t  dry run (implies verbose).
	       ^T${PGM} -H^t
	         Show an extensive description of the ^Bbuild header^b.
	       ^T${PGM} -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
function header-help { # {{{1
	sparkle <<-\
	\SPARKLE-DOC

    ^BEXTENSIVE BUILD HEADER DESCRIPTION^b

    The build header must occur before the first blank line in the file.

    In order to support various comment styles, each header declaration 
    line may contain any number of characters before the declaration
    and looks like:

        ^TBUILD-OPTS (clang)^t
        ^T: -opt^t
        ^T# some comment^t
        ^T:s=Linux: --linux-option^t
        ^T:s=Darwin:---some-text^t
        ^T: --darwin-option1^t
        ^T: --darwin-option2^t
        ^T:---some-text^t
        ^T---^t

    The compiler/assembler/etc name is in parenthesis after the
    term ^BBUILD-OPTS^b and more than ^BBUILD-OPTS^b declaration
    is allowed, each one run in turn.

    The first triple dash ends the build header.
    each ^T:flag=SomeText:^t is a uname flag set, if the text matches
    ^T$(uname -^t^Uflag^u^T)^t, then the option is used.
	SPARKLE-DOC
	exit 0
} # }}}1
typeset verbose=false dryrun=false TAB='	'
# process -options {{{1
function bad_programmer {	# {{{2
	die 'Programmer error:'	\
		"  No getopts action defined for [1m-$1[22m."
  };	# }}}2
while getopts ':nvHh' Option; do
	case $Option in
		n)	verbose=true; dryrun=true;								;;
		v)	verbose=true;											;;
		H)	header-help | less;										;;
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
function file-exists { #{{{1
	[[ -f $1 ]]&& return 0
	desparkle "$1"
	warn "File not found: ^B$REPLY^b, ^WSkipping^w."
	return 1
} # }}}1
function file-is-readable { #{{{1
	[[ -r $1 ]]&& return 0
	desparkle "$1"
	warn "^B$REPLY^b is unreadable, ^WSkipping^w."
	return 1
} # }}}1
function parse-warn { #{{{1
	typeset msg
	desparkle "$2"
	msg[0]="Syntax Error, $1"
	msg[1]="Line ^S$3^s, ^S$REPLY^s."
	[[ -n $4 ]]&& {
		desparkle "$4"
		msg[2]="> ^F{4}$REPLY^f <"
	  }
	warn "${msg[@]}"
} # }}}1
function __CC { #{{{1
	typeset words sname="${XFILE:-$1}" bname="${sname%.*}"
	set -A words -- $2
	typeset cc="${words[0]}"
	unset words[0]
	typeset cc_opts="${words[*]}"

	typeset output='' cmd="${cmd##+([ $TAB])}"
	[[ $cmd == *-[co][ $TAB] ]]|| output="-o '$bname' "

	typeset ALL='all'
	[[ $cc == clang ]]&& ALL='everything'

	REPLY="$cc -W$ALL $outopt'$sname' $cc_opts"
} # }}}1
function __nasm		{ REPLY="$2 $1"; }
function __ld		{ REPLY="$2 ${1%.*}.o"; }
function __clang	{ __CC "$@"; }
function __gcc		{ __CC "$@"; }
function __ragel { #{{{1
	typeset bname="${1%.*}" oext=c outopt='' cmd="$2"
	if [[ $cmd == *'-o '* ]]; then
		XFILE="${cmd#*-o }"
		XFILE="${XFILE%% *}"
	else
	fi
} # }}}1

rx_sets_outfile='(^|[ '"$TAB"'])-[co][[:>:]]'
bofile='build.output'
totalerrs=0
XFILE=''

print "build $*"  >"$bofile"
print '----'     >>"$bofile"




# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
