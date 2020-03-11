#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-08-11:tw/20.32.03z/32e3d26>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH} ${COLUMNS:=$(tput cols)}

# The $colors array was generated using the formula
#   16 + (36*R) + (6*G) + B
# for values of R, G, and B
#
#     R  0 1 1 2 2 3 3 4 4 5 5 5 4 4 3 3 2 2 1 1 0 0 0 0 0 0 0 0 0 0
#     G  0 0 0 0 0 0 0 0 0 0 0 1 1 2 2 3 3 4 4 5 5 5 4 4 3 3 2 2 1 1
#     B  5 5 4 4 3 3 2 2 1 1 0 0 0 0 0 0 0 0 0 0 0 1 1 2 2 3 3 4 4 5
#
c1=' 57    56    92    91   127   126   162   161   197   196
	202   166   172   136   142   106   112    76    82    46
	 47    41    42    36    37    31    32    26    27    21
	'
# A more consistent intensity (brightness) by using only every other set 
# where R+G+B = 5, but at a loss of transition smoothness. This is 
# mostly noticible when using the invert flag.
c2=' 57    92    127   162   197
	202   172   142   112    82
	 47    42    37    32    27
	'
set -A colors -- $c1

typeset -i -- hue=0 cpc=2 C=${#colors[*]} bfg=38 shft=2
typeset    -- dashopt=false

# we MUST use a bourne shell declaration to use typeset
reqInt() {
	[[ $3 == ?([+-])+([0-9]) ]]|| {
		-die "Option %S-$1%s (%B$2%b) is not a valid %Binteger%b."
	  }
	typeset -i $2=$3
}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t ^[^Uoptions^u^] ^[^Uinfile^u ^U…^u]
	         Transform ^SSTDIN^s to rainbow colored ^SSTDOUT^s.
	         ^T-i^t      Invert. Color background rather than foreground.
	                 This also forces the line length to ^S$COLUMNS^s.
	         ^T-c^t ^Unum^u  Characters per color. The default is ^B${cpc}^b.
	         ^T-s^t ^Unum^u  Shift or slope. Changes the color shift per line.
	                 The default is ^B${shft}^b.
	         ^T-t^t      Use color ^Btable 2^b. The default is ^Btable 1^b.
	                 Table 1 has 30 colors, smooth hue change, and rough brightness.
	                 Table 2 has 15 colors, rough hue change, and smooth brightness.
	         ^T-u^t ^Unum^u Hue (0 → $#c1) ^B0^b, the default, means random.
	                 the range with ^T-t^t is 0 → $#c2.
	       ^T${PGM} -h^t
	         Show this help message.
	  ^F{172}These options are not compatible with the ^Bruby^b version.^f
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
function bad_programmer {	# {{{2
	die 'Programmer error:'	\
		"  No getopts action defined for [1m-$1[22m."
  };	# }}}2
while getopts ':c:is:tu:h' Option; do
	case $Option in
		c)	reqInt $Option cpc $OPTARG;							;;
		i)	bfg=48;typeset -L $COLUMNS ln='';					;;
		s)	reqInt $Option shft $OPTARG;						;;
		u)	reqInt $Option hue $OPTARG;							;;
		t)	set -A colors $c2; C=${#colors[*]};					;;
		h)	-usage $Usage;										;;
		\?)	-die "Invalid option: '-$OPTARG'.";					;;
		\:)	-die "Option '-$OPTARG' requires an argument.";		;;
		*)	bad_programmer "$Option";							;;
	esac
done
# remove already processed arguments
shift $(($OPTIND - 1))
# ready to process non '-' prefixed arguments
# /options }}}1
((cpc<0))&&		die '^Schars per color^s must be greater than ^B0^b.'
((hue<0))&&		die "^Shue^s must be between ^B0^b and ^B$C^b (incl)."
((C<hue))&&		die "^Shue^s must be between ^B0^b and ^B$C^b (incl)."

((shft<0))&& shft=$((shft%C)) # handle shft with large negative magnitude

typeset -L $cpc remove=''; gsub ' ' '?' "$remove"; remove="$REPLY"
function rainbowify-line {
	typeset -i ndx=$2
	typeset line="$1" p='' t=''
	while ((${#line}>$cpc)); do
		t="${line#$remove}"
		p="${line%"$t"}"
		line="$t"
		print -n "\033[$bfg;5;${colors[ndx]}m$p"
		ndx=$(( ((ndx+1)%C) ))
	done
	((${#line}))&& print -n "\033[$bfg;5;${colors[ndx]}m$line"
	print -n '\033[0m\n'
}

function rainbowify-stdin {
	local t='' p=''
	t="$(</dev/stdin)"
	# remove any existing ansi escapes
	while [[ $t == *'['+([!mK])[mK]* ]]; do
		p="$p${t%%'['+([!mK])[mK]*}"
		t="${t#'['+([!mK])[mK]*}"
	done
	t="$p$t"
	splitstr NL "$t"
	for ln in "${reply[@]}"; do
		hue=$(((hue+shft+C)%C)) # handles negative shft values
		rainbowify-line "$ln" $hue
	done
}

function cat-one-file { # {{{1
	local useFile=false
	if [[ $1 == '-' ]]; then
		$dashopt && {
			warn 'Skipping redundant ^Bstdin^b input.'
			return 1
		}
		dashopt=true
	else
		[[ -e $1 ]]|| {
			warn "No such file or directory ^S$1^s."
			return 1
		  }
		[[ -d $1 ]]&& {
			-warn "^S$1^s is a directory."
			return 1
		  }
		[[ -r $1 ]]|| {
			-warn "Cannot read ^S$1^s."
			return 1
		  }
		useFile=true
	fi
	if $useFile; then
		rainbowify-stdin <"$1"
	else
		rainbowify-stdin
	fi
	return 0
} # }}}1

function randomize-hue {
	hue=$( printf '%d' "'$(dd status=none count=1 bs=1 if=/dev/random)" )
	hue=$((hue%C))
}

((hue))|| randomize-hue
(($#))|| set -- - # Normalize input from STDIN handling
for f { cat-one-file $f; }


# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
