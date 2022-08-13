#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-11-20:tw/19.26.21z/8485b8>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}
DEPO="NOTES"
SUFFIX=".note"

# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t^[^T-a^t^] ^[^T-c^t^] ^[^T-^t^?^Udepo^u^]
	         List all notes for a directory.
	           ^T-a^t  List ALL notes from everywhere!
	           ^T-c^t  Compact (don't list dates)
	           If ^Udepo^u is given, use that instead of NOTES.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
WANT_DATES=true
A=false
N=false
while [[ ${1:-} == -* ]]; do
	SYSDEPO=${SYSDATA:?}/notes
	case ${1#-} in
		h)	usage;													;;
		c)	WANT_DATES=false;										;;
		a)	A=true; DEPO=$SYSDEPO; SUFFIX="";						;;
		ac)	A=true; DEPO=$SYSDEPO; SUFFIX=""; WANT_DATES=false;		;;
		ca)	A=true; DEPO=$SYSDEPO; SUFFIX=""; WANT_DATES=false;		;;
		*)	N=true; typeset -u DEPO=${1#-}; D=$1;					;;
	esac
	shift
done
if $N; then
	(($#))&& die "Unexpected parameters. None expected with ^T$D^t."
else
	(($#>1))&& die "Too many parameters. Expected at most one (1)."
	[[ -n ${1:-} ]]&& {
		N=true
		typeset -u DEPO=$1
		D=$1
	  }
fi
$A && $N && die "Cannot use ^T-a^t ^Band^b ^T$D^t at the same time."
# /options }}}1

needs awk less sparkle needs-cd

[[ -d $DEPO ]]|| exit 0		#empty
needs-cd -or-die "$DEPO"

TAB='	'
NL='
' # < ^ capture newline
IFS='
'
set -- $(/bin/ls *"$SUFFIX" 2>/dev/null|sort -n)
(($#))|| exit 0	#empty

integer i=0 x=0
for H; do
	if [[ -a $H ]]; then
		notes[i++]="$H"
	else
		badlinks[x++]="$H"
	fi
done

AWKPGM=$(</dev/stdin) <<-\
	\===AWK===
		/<@\(#\)tag:/ {next}
		FNR == 2 && /^[0-9][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9].* Z/ {
				if (skipdate) {next}
				if (FNR != NR) { print "" }
				print "^B"$0"^b"
				next
			}
		# otherwise
			{print}
	===AWK===

function main {
	local s=1 pager SPARKLE_FORCE_COLOR
	$WANT_DATES && s=0

	if [[ -t 1 ]]; then
		pager="less -iMSx4 -FXc"
		SPARKLE_FORCE_COLOR=true
	else
		pager=cat
	fi

	IFS=" ${TAB:?}${NL:?}"
	awk -v skipdate=$s "$AWKPGM" "${notes[@]}"|sparkle|$pager
	((x))&& warn "Bad links:" "${badlinks[@]}"
}
main; exit 0


# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
