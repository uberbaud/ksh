#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2023-01-16,21.33.46z/59d92b2>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}
use-app-paths new

FILEARG=
FILETYPE=
TAB='	'

set -A Dictionary --
STANDARDS='FILE AUTHOR IDENT DESCRIPTION'
EXTRAS=
AUTHOR=${AUTHOR:-$(
	set -f
	IFS=:
	set -- $(getent passwd $(id -un))|| return
	print -rn -- "$5"
  )}
[[ -n $AUTHOR ]]|| die 'Could not get a value for ^VAUTHOR^v.'

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-f^t^] ^[^T-n^t^] ^[^T-x^t ^Umod^u^] ^[^T-t^t ^Uext^u^] ^Unew-file^u ^Udesc^u
	       ^T$PGM^t ^[^T-n^t^] ^[^T-x^t ^Umod^u^] ^T-z^t ^Uext^u ^[^Udesc^u ^S...]^s
	         Create and open for editing a new file from a template.
	           ^T-f^t      Force creation.
	           ^T-n^t      Do not edit (still does an intial VMS checkin).
	           ^T-t^t ^Uext^u  Use the template for ^Uext^u overriding any actual extension.
	           ^T-x^t      Include template specific ^Umod^u.
	           ^T-z^t ^Uext^u  Create a temporary file, the contents of which are copied to
	                   the clipboard after editing. No description required.
	           ^Udesc^u        Use ^Udesc^u for VMS description and in the file (replaces
	                         ^B«[DESCRIPTION]»^b). The description is ^Ball^b trailing words.
	         Default types and mods can be put into a file name ^T.new^t.
	       ^T$PGM^t ^T-T^t^|^T-V^t^|^T-X^t ^Utemplate^u
	           ^T-T^t      List templates.
	           ^T-V^t      List automagical variables and values for use in templates.
	           ^T-X^t      List available ^Umods^u for the ^Utemplate^u.
	       ^T$PGM -h^t^|^T-H^t^|^T-N^t
	           ^T-h^t      Show this help message.
	           ^T-H^t      Show a help overview of a template file.
	           ^T-N^t      Show a help for the ^B^T.new^t^b defaults file.
	===SPARKLE===
	exit 0
} # }}}
function use-temp-file { # {{{1
	local fTemp
	fTemp=$(mktemp) || die "Could not ^Tmktemp^t"
	add-exit-actions "rm -f '$fTemp'"
	fileIsTemp=true
	FILEARG=$fTemp
} # }}}1
# process -options {{{1
warnOrDie=die
wantEdit=true
fileIsTemp=false
modCount=0
set -A mods
while getopts ':fnt:xz:TVX:hHN' Option; do
	case $Option in
		f)	warnOrDie=warn;													;;
		h)	usage;															;;
		n)	wantEdit=false;													;;
		t)	FILETYPE=$OPTARG;												;;
		x)	mods[modCount++]=$OPTARG;										;;
		z)	FILETYPE=$OPTARG; use-temp-file;								;;
		H)	exec show-new-help.ksh NEW_TEMPLATES;							;;
		N)	exec show-new-help.ksh DOT_NEW_FILE;							;;
		T)	NOT-IMPLEMENTED -die "^V$Option^v option";						;;
		V)	exec show-new-help.ksh AUTOMAGICAL_VARIABLES;					;;
		X)	NOT-IMPLEMENTED -die "^V$Option^v option";						;;
		\?)	die USAGE "Invalid option: ^B-$OPTARG^b.";						;;
		\:)	die USAGE "Option ^B-$OPTARG^b requires an argument.";			;;
		*)	bad-programmer "No getopts action defined for ^T-$Option^t.";	;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
(($#))|| die "Missing required parameters ^Unew-file^u and ^Udescription^u."
FILEARG=$1; shift
(($#))|| die "Missing required ^Udescription^u."
DESCRIPTION=$*
# /options }}}1
function verify-template { # {{{1
	[[ -f $TEMPLATES_FOLDER/$1.tmpl || -f $TEMPLATES_FOLDER/$1/DESCRIPTION ]]
} # }}}1
function try-extension { # {{{1
	local ext
	[[ $FILE == *.* ]]|| return
	ext=${FILE##*.}
	verify-template $ext && FILETYPE=$ext
} #}}}
function transform-FILEARG-with-newrc { # {{{1
	local newrc ln cmd oldft
	oldft=$FILETYPE
	newrc=${XDG_CONFIG_HOME:-/nonesuch}/etc/new.rc
	[[ -f $newrc ]]|| return
	{ # block for redirected input from $newrc
		while IFS= read ln; do
			[[ -z $ln || $ln == [\#\;$TAB]* ]]&& continue
			eval "[[ \$FILEARG == ${ln#*$TAB} ]]" || continue
			FILETYPE=${ln%%$TAB*}
			break
		done
		[[ -n $ln ]] && while IFS= read cmd; do
			[[ -z $cmd || $cmd == [\#\;]* ]]&& continue
			[[ $cmd != $TAB* ]]&& break
			cmd=${cmd#$TAB}
			eval "$cmd"
		done
	} <$newrc
	[[ -z $oldft || $oldft == $FILETYPE ]]||
		die "^Tnew.rc^t filetype (^B$FILETYPE^b) and" \
			"^T-t^t ^B$oldft^b filetypes do not match."
} #}}}
function set-type-and-mods { # {{{1
	local modlist
	FILETYPE=${1?}
	modlist=${2?}
	((modCount))&& return
	while [[ $modlist == *,* ]]; do
		mods[modCount++]=${modlist%%,*}
	done
	[[ -n $modlist ]]&& mods[modCount++]=$modlist
} # }}}1
function try-dot-new { # {{{1
	local ftype modlist
	[[ -f .new ]]|| return
	IFS=: read ftype modlist <.new
	[[ $ftype == !* ]]&& return 1
	set-type-and-mods $ftype "$modlist"
} #}}}
function handle-dot-new-redirs { # {{{1
	depth=0
	set -A redirs
	while [[ -f $fPATH/.new ]]; do
		# skip comments and blank lines
		while read ln; do
			[[ -z $ln || $ln == @([\;\#]*|+([[:space:]])) ]]|| break
		done <$fPATH/.new

		# break if directive is not a redirect
		[[ -n $ln && $ln == !* ]]|| break

		# get new path
		ln=${ln##!*([[:space:]])}
		[[ $ln == /* ]]|| ln=$fPATH/$ln # if new/next path is relative
		fPATH=$(realpath "$ln") ||
			die "Could not ^Trealpath^t ^B$ln^b." ${redirs[*]:+"${redirs[@]}"}
	
		# error handling bits
		redirs[depth++]=$fPATH
		((depth>=3))&& die "Too many ^T.new^t redirs." "${redirs[@]}"
	done
} # }}}1
function ShowVarList { # {{{
	local i k v l kvs
	for k; do
		i=${#k}
		((l<i))&& l=$i
	done
	typeset -L$l k
	i=0
	for k; do
		eval v=\$$k
		kvs[i++]="^V$k^v ^S⇒^s $v"
	done
	notify ${kvs[*]:+"${kvs[@]}"}
} # }}}1
function extra-var-list { # {{{
	local i k v
	set -- $*
	(($#))|| return

	i=$((${Dictionary[*]:+${#Dictionary[*]}}))
	for k; do
		eval v=\${$k:-}
		Dictionary[i++]=-D$k=$v
	done
} # }}}1

needs warnOrDie needs-vars stemma-tag
needs-vars TEMPLATES_FOLDER

transform-FILEARG-with-newrc
if [[ $FILEARG == */* ]]; then
	fPATH=$(realpath "${FILEARG%/*}")
	FILE=${FILEARG##*/}
else
	fPATH=$PWD
	FILE=$FILEARG
fi

handle-dot-new-redirs
needs-cd -or-die "$fPATH"

[[ -n ${FILETYPE:-} ]]|| try-extension || try-dot-new ||
	die "Unable to determine which template to use."

IDENT=$(stemma-tag)
ShowVarList FILEARG fPATH FILE FILETYPE EXTRAS IDENT
notify "mods: ${mods[*]:-}"
extra-var-list "$STANDARDS" "$EXTRAS"
for d in "${Dictionary[@]}"; do
	print -r -- "  $d"
done

# Copyright (C) 2023 by Tom Davis <tom@greyshirt.net>.
