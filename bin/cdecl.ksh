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
	             ^T-f^t  static function prototypes
	             ^T-m^t  macro definitions
	             ^T-s^t  structures (including ^Stypedef^sed)
	             ^T-u^t  unions (including ^Stypedef^sed)
	             ^T-t^t  typedefs (excluding ^Senums^s and ^Sstructures^s)
	             ^T-F^t  function prototypes
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
wENUMS=false
wFUNCS=false
wMACROS=false
wSTRUCTS=false
wUNIONS=false
wTYPEDEFS=false
wFEXTS=false
QUIET=false
RAWOUT=false
while getopts ':efmsFtuqrh' Option; do
	case $Option in
		e)	wENUMS=true;										;;
		f)	wFUNCS=true;										;;
		m)	wMACROS=true;										;;
		s)	wSTRUCTS=true;										;;
		u)	wUNIONS=true;										;;
		t)	wTYPEDEFS=true;										;;
		F)	wFEXTS=true;										;;
		q)	QUIET=true;											;;
		r)	RAWOUT=true;										;;
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
function get-source-text { # {{{1
	local style
	style="$(</dev/stdin)" <<-\
		\===
		BasedOnStyle: LLVM,
		ColumnLimit: 9999,
		AllowShortBlocksOnASingleLine: false,
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
	for f; do
		clang-format -style="{$style}" "$f"	|
			sed -e "s/^/$f	/"
	done
} # }}}1

needs clang-format nl sed
$RAWOUT||
$wENUMS||$wFUNCS||$wFEXTS||$wMACROS||$wSTRUCTS||$wUNIONS||$wTYPEDEFS||
	die 'No filter(s) specified.'

(($#))|| set -- *.[ch]


if $QUIET; then
	PRNLN='function prnln(F,L,X) { printf "%s%s,L,X }'
else
	PRNLN='function prnln(F,L,X) { printf "%s:%s%s",F,L,X }'
fi

fMACROS="$(</dev/stdin)" <<-\
	\==AWK==
		$2 ~ /^#define/ {
			prnln($1,$2)
			while ($2 ~ /\\$/) {
				if (getline != 1) break
				printf "%s", $2
			}
			pnl()
		}
	==AWK==
fSTRUCTS="$(</dev/stdin)" <<-\
	\==AWK==
		$2 ~ /^(typedef )?struct [A-Za-z_][A-Za-z0-9_]* {/ {
			prnln($1,$2)
			while ($2 !~ /^}.*;$/) {
				if (getline != 1) break
				printf "%s", $2
			}
			pnl()
		}
	==AWK==

fFUNCS='$2 ~ /static.*\) {$/ {sfunc=1;prnfn($1,$2);pnl();next}'
fskipFUNCS='$2 ~ /static.*\) {$/ {sfunc=1}'
fFEXTS='$2 ~ /\) {$/ && !sfunc {prnfn($1,$2);pnl();next}'

function not-implemented { # {{{1
	x=$(</dev/stdin) <<-\
	==AWK==
	END {
		print "\\033[31m$1 filter not implemented.\\033[38m" >"/dev/stderr"
	}
	==AWK==
	print -- "$x"
} # }}}1
fENUMS=$(not-implemented enums)
fUNIONS=$(not-implemented union)
fTYPEDEFS=$(not-implemented typedef)

# wrap script guts in a function so edits to this script file don't 
# affect running instances of the script.
function main {
	$wENUMS			|| fENUMS=
	$wFEXTS			|| { fFEXTS=; fskipFUNCS=; }
	$wFUNCS			|| fFUNCS="$fskipFUNCS"
	$wMACROS		|| fMACROS=
	$wSTRUCTS		|| fSTRUCTS=
	$wUNIONS		|| fUNIONS=
	$wTYPEDEFS		|| fTYPEDEFS=
	AWK_PGM=$(</dev/stdin) <<-\
		===AWK===
			$PRNLN
			function pnl() {print ""}
			function prnfn(F,N) { sub(/ {\$/,"",N); prnln(F,N,";"); }
			\$2 ~ /^ / {next}
			{sfunc=0}
			$fENUMS
			$fFUNCS
			$fFEXTS
			$fMACROS
			$fSTRUCTS
			$fUNIONS
			$fTYPEDEFS
		===AWK===
	$RAWOUT && AWK_PGM="$PRNLN {prnln(\$1,\$2);print \"\"}"

	#print -- "$AWK_PGM"

	get-source-text "$@" | awk -F'\t' "$AWK_PGM"
}

main "$@"; exit

# Copyright (C) 2020 by Tom Davis <tom@greyshirt.net>.
