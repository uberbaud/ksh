#!/bin/ksh

# <@(#)tag:tw.csongor.greyshirt.net,2020-10-17,19.04.35z/4cb78fc>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-q^t^] ^T-r^t^|^T-efmsF^t ^[^Usources^u^]
	         Print useful bits from C source files
	           Filter options:
	             ^T-e^t  enums (includeing ^Stypedef^sed)
	             ^T-f^t  non-static function definitions
	             ^T-p^t  non-static function prototypes
	             ^T-m^t  macro definitions
	             ^T-s^t  structures (including ^Stypedef^sed)
	             ^T-u^t  unions (including ^Stypedef^sed)
	             ^T-t^t  typedefs (excluding ^Senums^s and ^Sstructures^s)
	             ^T-f^t  static function definitions
	             ^T-P^t  static function prototypes
	           Other options:
	             ^T-q^t  Do not print filenames.
	             ^T-r^t  Print ^Bclang-format^b output, do not filter.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
function bad_programmer {	# {{{2
	die 'Programmer error:'	\
		"  No getopts action defined for [1m-$1[22m."
  };	# }}}2
QUIET=false
RAWOUT=false

wFnDefs=false; wStFnDefs=false; wStFnProts=false; wFnProts=false
wENUMS=false; wMACROS=false; wSTRUCTS=false; wTYPEDEFS=false; wUNIONS=false

while getopts ':FPefmpqrstuh' Option; do
	case $Option in
		F)	wStFnDefs=true;										;;
		P)	wStFnProts=true;									;;
		e)	wENUMS=true;										;;
		f)	wFnDefs=true;										;;
		m)	wMACROS=true;										;;
		p)	wFnProts=true;										;;
		q)	QUIET=true;											;;
		r)	RAWOUT=true;										;;
		s)	wSTRUCTS=true;										;;
		t)	wTYPEDEFS=true;										;;
		u)	wUNIONS=true;										;;
		h)	usage;												;;
		\?)	die "Invalid option: ^B-$OPTARG^b.";				;;
		\:)	die "Option ^B-$OPTARG^b requires an argument.";	;;
		*)	bad_programmer "$Option";							;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
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
function debug-show-filters { # {{{1
	E=$(print \\033)
	print -nu2 -- ' \033[34m>>>\033[39m sed'
	for f in "${filters[@]}"; do
		if [[ $f == -* ]]; then
			f="$E[35m$f$E[39m"
		else
			f="'$E[4m$f$E[24m'"
		fi
		print -rnu2 -- " $f"
	done
	print -u2
} # }}}1
# fmt_bare {{{1
fmt_bare="$(</dev/stdin)" <<-\
	\===
	BasedOnStyle: LLVM,
	ColumnLimit: 9999,
	BreakBeforeBraces: Custom,
	BraceWrapping: {
			AfterClass: false,
			AfterControlStatement: false,
			AfterEnum: false,
			AfterFunction: false,
			AfterNamespace: false,
			AfterStruct: false,
			AfterUnion: false,
			AfterExternBlock: false,
			BeforeCatch: true,
			BeforeElse: true,
		}
	AlignEscapedNewlines: Left,
	AllowShortBlocksOnASingleLine: false,
	AllowShortFunctionsOnASingleLine: false,
	IndentPPDirectives: None,
	StatementMacros: [ DBG_CHKPNT, Q_UNUSED, QT_REQUIRE_VERSION ],
	UseTab: Never,
	IndentWidth: 1,
	===
# }}}1
# fmt_pretty {{{1
fmt_pretty="$(</dev/stdin)" <<-\
	\===
	BasedOnStyle: LLVM,
	ColumnLimit: 80,
	BreakBeforeBraces: Custom,
	BraceWrapping: {
			AfterClass: false,
			AfterControlStatement: false,
			AfterEnum: false,
			AfterFunction: false,
			AfterNamespace: false,
			AfterStruct: false,
			AfterUnion: false,
			AfterExternBlock: false,
			BeforeCatch: true,
			BeforeElse: true,
		}
	AlignAfterOpenBracket: AlwaysBreak,
	AlignEscapedNewlines: Left,
	AlignConsecutiveMacros: true,
	AlignTrailingComments: false,
	AllowAllArgumentsOnNextLine: true,
	AllowAllParametersOfDeclarationOnNextLine: true,
	AllowShortBlocksOnASingleLine: Always,
	AllowShortFunctionsOnASingleLine: All,
	AlwaysBreakAfterReturnType: None,
	SpaceBeforeParens: ControlStatements,
	SpaceInEmptyBlock: false,
	SpaceInEmptyParentheses: false,
	SpacesInConditionalStatement: true,
	SpacesInParentheses: false,
	IndentPPDirectives: None,
	UseTab: Never,
	IndentWidth: 4,
	===
# }}}1
function process-one-file { # {{{1
	local s
	ADD_FILE=''
	gsub '\' '\\' "$f" s
	gsub '/' '\/' "$s" s
	$QUIET || ADD_FILE="s/^/$s	/"
	sed -E -e '/^#[[:space:]]*include/d' "$f"	|
		clang-cpp								|
		clang-format -style="{$fmt_bare}"		|
		sed "${filters[@]}"						|
		clang-format -style="{$fmt_pretty}"		|
		sed -E -e "$ADD_FILE"

} # }}}1

needs clang-format nl sed
$RAWOUT||
	$wENUMS||$wFnProts||$wFnDefs||$wMACROS||$wSTRUCTS||$wUNIONS||
	$wTYPEDEFS||$wStFnProts||$wStFnDefs||$wStFnProts||
		die 'No filter(s) specified.'
(($#))|| set -- *.[ch]

new-array filters
# filters set up # {{{1
if $RAWOUT; then
	$wENUMS			&& die 'Conflicting flags, ^Braw^b and ^Bfilters^b.'
	$wFnProts		&& die 'Conflicting flags, ^Braw^b and ^Bfilters^b.'
	$wFnDefs		&& die 'Conflicting flags, ^Braw^b and ^Bfilters^b.'
	$wMACROS		&& die 'Conflicting flags, ^Braw^b and ^Bfilters^b.'
	$wSTRUCTS		&& die 'Conflicting flags, ^Braw^b and ^Bfilters^b.'
	$wUNIONS		&& die 'Conflicting flags, ^Braw^b and ^Bfilters^b.'
	$wTYPEDEFS		&& die 'Conflicting flags, ^Braw^b and ^Bfilters^b.'
	$wStFnProts		&& die 'Conflicting flags, ^Braw^b and ^Bfilters^b.'
	$wStFnDefs		&& die 'Conflicting flags, ^Braw^b and ^Bfilters^b.'
	$wStFnProts		&& die 'Conflicting flags, ^Braw^b and ^Bfilters^b.'
	+filters -E
else
	+filters -n -E

	if $wStFnProts || $wFnProts || $wFnDefs || $wStFnDefs; then
		# remove matching conditionals
		+filters -e '/[[:<:]](switch|if|while|for)[[:space:]]*\(/d'
		# remove matching assignments
		+filters -e '/=/d'
	fi

	# filter in FUNCTION PROTOCOLS
	if $wStFnProts && $wFnProts; then
		+filters -e '/\);$/p'
	elif $wStFnProts; then
		+filters -e '/static.*\);$/p'
	elif $wFnProts; then
		+filters -e '/static.*\);$/d'
		+filters -e '/\);$/p'
	fi

	# filter in FUNCTION DEFINITIONS

	# We're going to pass the results through `clang-format` again, SO
	# we need to make everything syntatically correct C. Since we're
	# discarding the function body, we need to transform function
	# definitions into prototypes, but if we just replace the brace with
	# a semicolon we won't be able to tell definitions from prototypes,
	# but if we just tack on an empty body the output might not be as
	# useful for creating headers and such, SO we'll just comment them
	# out.
	def2prot='{s@ {$@; //{@;p;}'
	if $wFnDefs && $wStFnDefs; then
		+filters -e '/\(.*\) {$/'"$def2prot"
	elif $wStFnDefs; then
		+filters -e '/static.*\(.*\) {$/'"$def2prot"
	elif $wFnDefs; then
		+filters -e '/static.*\) {$/d'
		+filters -e '/\(.*\) {$/'"$def2prot"
	fi


	$wENUMS			&& not-implemented enums
	$wMACROS		&& not-implemented macros
	$wSTRUCTS		&& not-implemented structs
	$wTYPEDEFS		&& not-implemented typedefs
	$wUNIONS		&& not-implemented unions
fi
# }}}1

function main {
	for f { process-one-file "$f"; }
	[[ -n ${DEBUG:-} ]]&& debug-show-filters
}

main "$@"; exit

# Copyright (C) 2020 by Tom Davis <tom@greyshirt.net>.
