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
	^F{4}Usage^f: ^T${PGM}^t ^[^T-alstxX^t^] ^F{1}R^f ^F{2}G^f ^F{4}B^f
	         Outputs the 256 color number of the ^Brgb^b value.
	         Each of the ^Brgb^b is a number between ^B0^b and ^B5^b.
	       ^T${PGM}^t ^[^T-alstxX^t^] ^Ucolor-code^u
	         Outputs the ^BR^b ^BG^b ^BB^b of that ^Ucolor-code^u.
	         Where color-code is a number between 0 and 255 inclusive.
	       ^T${PGM}^t ^[^T-alstxX^t^] ^T#^t^Uhex-color^u
	         Outputs the ansi ^BR^b ^BG^b ^BB^b nearest to the full color
	         ^Itrue color^i ^Uhex-color^u.
	       ^GOUTPUT FORMAT FLAGS^g
	         ^T-a^t  all (index hex R G B) on one line, easily parsed.
	         ^T-l^t  default long detailed output format
	         ^T-s^t  short output format (only shows RGB as 1-5 or ^T*^t)
	         ^T-t^t  color table index format (only shows index as 0-255)
	         ^T-x^t  hex RGB format (shows RGB as #rrggbb as [0-f]{6})
	         ^T-X^t  hex RGB format (shows RGB as #rrggbb as [0-F]{6})
	             ^GFormat flags are mutually exclusive. Last one wins.^g
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
SHOW=full
while getopts ':ahlstxX' Option; do
	case $Option in
		a)	SHOW=all;												;;
		l)	SHOW=full;												;;
		s)	SHOW=short;												;;
		t)	SHOW=clrtbl;											;;
		x)	SHOW=hex;												;;
		X)	SHOW=HEX;												;;
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
set -A palG -- 08 12 1c 26 30 3a 44 4e 58 62 6c 76 80 8a \
				94 9e a8 b2 bc c6 d0 da e4 ee # grayscale
function tc→256c { # {{{1
	typeset -i10 c=$1 C=0
	# CLOSEST COLOR
	if		((c<48));	then NEARLY=0
	elif	((c<115));	then NEARLY=1
	elif	((c<155));	then NEARLY=2
	elif	((c<195));	then NEARLY=3
	elif	((c<235));	then NEARLY=4
	else					 NEARLY=5
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
	elif	((c<243));	then GREY=255
	else					 GREY=15
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
	tc→256c $r; rC=$NEARLY rG=$GREY
	tc→256c $g; gC=$NEARLY gG=$GREY
	tc→256c $b; bC=$NEARLY bG=$GREY
	if ((rG==gG && rG==bG)); then # it's grey
		ANSI=$rG
		if ((rG==16)); then
			HEX='#000000'
		elif ((rG==15)); then
			HEX='#ffffff'
		else
			typeset p=${palG[rG-232]}
			HEX="#$p$p$p"
		fi
	else # it's a color, not grey
		ANSI=$(((((rC*6)+gC)*6+bC)+16))
		HEX="#${palX[rC]}${palX[gC]}${palX[bC]}"
		R=$rC; G=$gC; B=$bC
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
	warn 'The default pallette is often changed.' 'Therefore these are only approximations.'
	case $1 in
		 0) HEX='#000000';		;;
		 1) HEX='#800000';		;;
		 2) HEX='#00cd00';		;;
		 3) HEX='#cdcd00';		;;
		 4) HEX='#1e90ff';		;;
		 5) HEX='#cd00cd';		;;
		 6) HEX='#00cdcd';		;;
		 7) HEX='#e5e5e5';		;;
		 8) HEX='#7f7f7f';		;;
		 9) HEX='#ff0000';		;;
		10) HEX='#00ff00';		;;
		11) HEX='#ffff00';		;;
		12) HEX='#5c5cff';		;;
		13) HEX='#ff00ff';		;;
		14) HEX='#00ffff';		;;
		15) HEX='#ffffff';		;;
	esac
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
} # }}}1
function set-232-colors { # {{{1
	typeset -i r=0 g=0 b=0 x=$(($1-16))
	b=$((x%6));		x=$((x/6))
	g=$((x%6));
	r=$((x/6))
	HEX="#${palX[r]}${palX[g]}${palX[b]}"
	R=$r; G=$g; B=$b
} # }}}1
function show-all { print -r -- "$ANSI $HEX $R $G $B"; }
function show-full { # {{{1
	needs figlet term-does-utf8
	splitstr NL "$(figlet "$ANSI")" fig

	Latin='\0303\0211\0303\0247\0303\0276\0303\0260'
	term-does-utf8 || Latin='\0311\0347\0376\0360'
	Alpha="ABCDefgh$(print -- "$Latin")"

	smA='\033[0m    \033[48;5;%dm            '
	smB='\033[0m    \033[38;5;%dm%s'
	smC='\033[0m     : %s\n'
	showme="  $smA$smB$smC"

	typeset -L 33 RGB="$R $G $B"
	printf '%40s %s\n' "$RGB"                           "${fig[0]}"
	printf "$showme" $ANSI $ANSI "$Alpha"		"${fig[1]}"
	printf "$showme" $ANSI $ANSI '_0123456789-' "${fig[2]}"
	printf "$showme" $ANSI $ANSI '!@#$%^&*([{|' "${fig[3]}"
	printf '%17s %22s %s\n' "$ANSI $HEX" ':'   "${fig[4]}"
} # }}}1
function show-short { print -r -- "$R $G $B"; }
function show-clrtbl { print -r -- "$ANSI"; }
function show-HEX { print -r -- "$HEX"; }
function show-hex { typeset -l x=$HEX; print -r -- "$x"; }
needs term-has-256-colors
term-has-256-colors ||
	warn 'This terminal does not support 256 colors.'

R=\*; G=\*; B=\*; ANSI=; typeset -u HEX=
x3=[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]
if (($#==1)); then
	x=$1
	if		[[ $x == \#$x3 ]];		then set-hex3 $1
	elif	[[ $x == \#$x3$x3 ]];	then set-hex6 $1
	elif	[[ $x == *[!0-9]* ]];	then std-die;
	elif	((  0<=x && x< 16));	then set-16-colors ${ANSI:=$1}
	elif	(( 16<=x && x<232));	then set-232-colors ${ANSI:=$1}
	elif	((232<=x && x<256));	then set-grey-scale ${ANSI:=$1}
	else
		std-die;
	fi
elif (($#==3)); then
	for y; do
		[[ $y == *[!0-9]* ]]&&	bad-color-die
		((0<=y && y<=5))||	bad-color-die
	done

    R=$1 G=$2 B=$3
	ANSI=$((16+(36*R)+(6*G)+B))
	HEX="#${palX[R]}${palX[G]}${palX[B]}"
else
	std-die
fi

show-$SHOW

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
