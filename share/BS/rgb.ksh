#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-08-20:tw/00.59.53z/4219937>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T${PGM}^t ^F{1}R^f ^F{2}G^f ^F{4}B^f
	         Outputs the 256 color number of the ^Brgb^b value.
	         Each of the ^Brgb^b is a number between ^B0^b and ^B5^b.
	       ^T${PGM}^t ^Ucolor-code^u
	         Outputs the ^BR^b ^BG^b ^BB^b of that ^Ucolor-code^u.
	         Where color-code is a number between 0 and 255 inclusive.
	       ^T${PGM}^t ^T#^t^Uhex-color^u
	         Outputs the ansi ^BR^b ^BG^b ^BB^b nearest to the full color
	         ^Itrue color^i ^Uhex-color^u.
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
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
function std-die { # {{{1
	sparkle <<-\
	==SPARKLE==
	  ^EFAILED^e: I need ^Bthree^b (3) numbers (^F{1}Red^f, ^F{2}Green^f, and ^F{4}Blue^f), each between ^B0^b and ^B5^b,
	          or one (1) number between ^B0^b and ^B255^b,
	          or an ocothorpe prefixed three (3) or six (6) digit hex-code.
	==SPARKLE==
	exit 1
} # }}}1
function bad-color-die { # {{{1
	sparkle <<-\
	==SPARKLE==
	  ^EFAILED^e: Each ^F{1}R^f ^F{2}G^f ^F{4}B^f value MUST be ^B0^b, ^B1^b, ^B2^b, ^B3^b, ^B4^b, or ^B5^b.
	==SPARKLE==
	exit 1
} # }}}1
set -A palA -- 00 32 65 99 CC FF # well distributed
set -A palX -- 00 5F 87 AF D7 FF # xterm
set -A palG -- 08 12 1c 26 30 3a 44 4e 58 62 6c 76 80 8a 94 9e a8 b2 bc c6 d0 da e4 ee
function tc→256c { # {{{1
	typeset -i10 c=$1 C=0
	# CLOSEST COLOR
	if		((c<48));	then CLOSE=0
	elif	((c<115));	then CLOSE=1
	elif	((c<155));	then CLOSE=2
	elif	((c<195));	then CLOSE=3
	elif	((c<235));	then CLOSE=4
	else					 CLOSE=5
	fi
	# MAYBE IT'S A GREY?
	if		((c<4));	then GREY=16
	elif	((c<13));	then GREY=232
	elif	((c<23));	then GREY=233
	elif	((c<33));	then GREY=234
	elif	((c<43));	then GREY=235
	elif	((c<53));	then GREY=236
	elif	((c<63));	then GREY=237
	elif	((c<73));	then GREY=238
	elif	((c<83));	then GREY=239
	elif	((c<93));	then GREY=240
	elif	((c<103));	then GREY=241
	elif	((c<113));	then GREY=242
	elif	((c<123));	then GREY=243
	elif	((c<133));	then GREY=244
	elif	((c<143));	then GREY=245
	elif	((c<153));	then GREY=246
	elif	((c<163));	then GREY=247
	elif	((c<173));	then GREY=248
	elif	((c<183));	then GREY=249
	elif	((c<193));	then GREY=250
	elif	((c<203));	then GREY=251
	elif	((c<213));	then GREY=252
	elif	((c<223));	then GREY=253
	elif	((c<233));	then GREY=254
	else					 GREY=255
	fi
} # }}}1
function set-hex6 { # {{{1
	[[ $1 == \#$x3$x3 ]]|| die 'Bad Programmer!'
	typeset -i10 hex="16$1" x r g b rC gC bC rG gG bG
	b=$((x%16#100))
	x=$((x/16#100))
	r=$((hex/16#10000))
	x=$((hex%16#10000))
	g=$((x/16#100))
	b=$((x%16#100))
	tc→256c $r; rC=$CLOSE rG=$GREY
	tc→256c $g; gC=$CLOSE gG=$GREY
	tc→256c $b; bC=$CLOSE bG=$GREY
	if ((rG==gG && rG==bG)); then
		ANSI=$rG
		if ((rG==16)); then
			HEX='#000000'
		else
			typeset p=${palG[rG-232]}
			HEX="#$p$p$p"
		fi
		set -A rgb -- '' '' '' "$HEX" "$ANSI"
	else
		ANSI=$(((((rC*6)+gC)*6+bC)+16))
		HEX="#${palX[rC]}${palX[gC]}${palX[bC]}"
		set -A rgb -- $rC $gC $bC "$HEX" "$ANSI"
	fi
} # }}}1
function set-hex3 { # {{{1
	local hex r g b
	hex=${1#\#}
	r=${hex%??}
	b=${hex#??}
	g=${hex#?}; g=${g%?}
	set-hex6 "#$r$r$g$g$b$b"
} # }}}1
function set-16-colors { # {{{1
	local hex
	warn 'The default pallette is often changed.' 'Therefore these are only approximations.'
	case $1 in
		 0) hex='#000000';		;;
		 1) hex='#800000';		;;
		 2) hex='#008000';		;;
		 3) hex='#808000';		;;
		 4) hex='#000080';		;;
		 5) hex='#800080';		;;
		 6) hex='#008080';		;;
		 7) hex='#c0c0c0';		;;
		 8) hex='#808080';		;;
		 9) hex='#ff0000';		;;
		11) hex='#ffff00';		;;
		12) hex='#0000ff';		;;
		13) hex='#ff00ff';		;;
		14) hex='#00ffff';		;;
		15) hex='#ffffff';		;;
	esac
	set -A rgb -- '' '' '' "$hex" "$1"
} # }}}1
function set-grey-scale { #{{{1
	typeset hex
	case $1 in
		232)	hex='08';		;;
		233)	hex='12';		;;
		234)	hex='1c';		;;
		235)	hex='26';		;;
		236)	hex='30';		;;
		237)	hex='3a';		;;
		238)	hex='44';		;;
		239)	hex='4e';		;;
		240)	hex='58';		;;
		241)	hex='62';		;;
		242)	hex='6c';		;;
		243)	hex='76';		;;
		244)	hex='80';		;;
		245)	hex='8a';		;;
		246)	hex='94';		;;
		247)	hex='9e';		;;
		248)	hex='a8';		;;
		249)	hex='b2';		;;
		250)	hex='bc';		;;
		251)	hex='c6';		;;
		252)	hex='d0';		;;
		253)	hex='da';		;;
		254)	hex='e4';		;;
		255)	hex='ee';		;;
	esac
	HEX="#$hex$hex$hex"
	set -A rgb -- '' '' '' "$HEX" "$1"
} # }}}1
function set-232-colors { # {{{1
	typeset -i r=0 g=0 b=0 x=$(($1-16))
	b=$((x%6));		x=$((x/6))
	g=$((x%6));
	r=$((x/6))
	HEX="#${palX[r]}${palX[g]}${palX[b]}"
	set -A rgb -- "$r" "$g" "$b" "$HEX" "$1"
} # }}}1
needs figlet term-does-utf8 term-has-256-colors
term-has-256-colors ||
	warn 'This terminal does not support 256 colors.'

x3=[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]
if (($#==1)); then
	x=$1
	if		[[ $x == \#$x3 ]];		then set-hex3 $1
	elif	[[ $x == \#$x3$x3 ]];	then set-hex6 $1
	elif	[[ $x == *[!0-9]* ]];	then std-die;
	elif	((  0<=x && x< 16));	then set-16-colors $1
	elif	(( 16<=x && x<232));	then set-232-colors $1
	elif	((232<=x && x<256));	then set-grey-scale $1
	else
		std-die;
	fi
	set -- "${rgb[@]}"
elif (($#==3)); then
    R=$1 G=$2 B=$3
	[[ $R == *[!0-9]* ]]&&	bad-color-die
	[[ $G == *[!0-9]* ]]&&	bad-color-die
	[[ $B == *[!0-9]* ]]&&	bad-color-die
	((0<=R && R<=5))||	bad-color-die
	((0<=G && G<=5))||	bad-color-die
	((0<=B && B<=5))||	bad-color-die

	ANSI=$((16+(36*R)+(6*G)+B))
	HEX="#${palX[R]}${palX[G]}${palX[B]}"
	set -A rgb -- $R $G $B "$HEX" "$ANSI"
else
	std-die
fi

showme='  '\
'\033[0m    \033[48;5;%dm            '\
'\033[0m    \033[38;5;%dm%s'\
'\033[0m     : %s\n'
splitstr NL "$(figlet "${rgb[4]}")" fig

Latin='\0303\0211\0303\0247\0303\0276\0303\0260'
term-does-utf8 || Latin='\0311\0347\0376\0360'
Alpha="ABCDefgh$(print -- "$Latin")"


typeset -L 33 RGB=${rgb[0]:-*} ${rgb[1]:-*} ${rgb[2]:-*}
printf '%40s %s\n' "$RGB"                           "${fig[0]}"
printf "$showme" ${rgb[4]} ${rgb[4]} "$Alpha"		"${fig[1]}"
printf "$showme" ${rgb[4]} ${rgb[4]} '_0123456789-' "${fig[2]}"
printf "$showme" ${rgb[4]} ${rgb[4]} '!@#$%^&*([{|' "${fig[3]}"
printf '%17s %22s %s\n' "${rgb[4]} ${rgb[3]}" ':'   "${fig[4]}"

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
