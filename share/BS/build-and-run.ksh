#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2022-05-17,20.16.23z/461e7f5>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-e^t^] ^Usrc^u
	         Uses header information in C file to set build environment,
	         runs ^Tmake^t ^O\${^o^Vsrc^v^O%^o^T.c^t^O}^o, and runs the resulting executable.
	         ^T-e^t  Open an editor and do make+run on saves.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
MAIN=make+run
while getopts ':eh' Option; do
	case $Option in
		e)	MAIN=loop;														;;
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
function show-get-set { print -ru2 -- "${1:?} = ${2:-}"; }
function first-time-get-set { # {{{1
	h3 'GET and SET variables'
	show-get-set "$1" "$2"
	showvar_fn=show-get-set
} # }}}1
function get-set-vars { # {{{1
	local TAB='	' line key value

	IFS= read line
	[[ $line == /\** ]]|| {
		warn \
			"In order to ^Bget^b and ^Bset^b variables, the first line"	\
			"^BMUST^b be the opening of a multi-line comment, but it"	\
			"isn't, so we're not setting the ^Tmake^t environment."
		return 0 # not a FATAL ERROR, so return OK
	  }

	# process variables
	while IFS=" $TAB" read -r line; do
		[[ $line == *\*/* ]]&& break # end of comment
		[[ $line == [A-Za-z_]*([A-Za-z0-9_])*([ $TAB])?(+)=* ]]|| continue

		# there's definitely an equals sign, we just tested, so we're
		# good
		key=${line%%=*}
		value=${line##"$key="*([ $TAB])}

		if [[ $key == *+ ]]; then
			key=${key%%*([ $TAB])+}
			eval value="\${$key:+\"\$$key \"}\$value"
		else
			key=${key%%*([ $TAB])}
		fi
		gsub '"' '\"' "$value" value
		eval value=\"$value\"
		export $key="$value"

		$showvar_fn "$key" "$value"
	done
	[[ -z ${PACKAGES:-} ]]|| {
		pkg-config --exists $PACKAGES || return
		CFLAGS=${CFLAGS:+"$CFLAGS "}$(pkg-config --cflags $PACKAGES)
		LDFLAGS=${LDFLAGS:+"$LDFLAGS "}$(pkg-config --libs $PACKAGES)
		export CFLAGS LDFLAGS
	  }
} # }}}1
function edit-c-file { #{{{1
	local E F T Cmd2 c2f
	shquote "$1" F
	E=${VISUAL:-${EDITOR:-vi}}
	[[ -e RCS/$F,v ]]&& {
		co -l -q "$F"
		T=$(mktemp)
		c2f=$KDOTDIR/share/BS/cat-to-file.ksh
		[[ -x $c2f ]]&&
			Cmd2="rcsdiff '$F'; rlwrap -s 0 $c2f -p 'ci> ' '$T'"
	  }

	${X11TERM:-xterm} -e ksh -c "$E $F${Cmd2:+; $Cmd2}" >/dev/null 2>&1
	pkill -HUP -lf -- "^watch-file -i $UUID"
	# For some reason, ci before kill makes kill not work
	[[ -e RCS/$F,v ]]&& {
		local rcsmsg='build-and-run'
		[[ -f $T ]]&& { rcsmsg=$(<$T); rm "$T"; }
		ci -u -q -m"${rcsmsg:-'~'}" "$F"
	  }
} #}}}1
function make+run { # {{{1
	get-set-vars <$CFILE	|| return # die if pkg-config error
	h3 "make $EXE"
	make "$EXE"				|| return

	[[ -f obj/$EXE ]]&& EXE=obj/$EXE
	if [[ -x $EXE ]]; then
		h3 "running $EXE"
		time (./"$EXE"; print -n '\n\033[A\033[48;5;238;36m\033[K')
		print -n '\033[0m'
		h3 "$EXE completed // rc = $?"
	elif [[ -a $EXE ]]; then
		warn "Weirdly, ^B$EXE^b is not executable."
	else
		warn "^Tmake^t completed successfully, but cannot find ^B$EXE^b."
	fi
} # }}}1
function clear-screen { print -u2 '\033[H\033[2J\033[3J\033[H\c'; }
function loop { #{{{1
	local cksum_previous cksum_current UUID

	needs pkill shquote subst-pathvars uuidgen watch-file

	subst-pathvars "$PWD" prnPathName

	UUID=$(uuidgen) # so edit-c-file can signal ONLY THIS watch-file
	edit-c-file "$CFILE" &
	cksum_previous=unedited
	h3 "$prnPathName / $UUID"
	while watch-file -i "$UUID" "$CFILE" 2>/dev/null; do
		[[ -f $CFILE ]]|| break
		cksum_current=$(cksum "$CFILE")
		[[ $cksum_current == $cksum_previous ]]&& clear-screen
		# date is outside quotes to eliminate extra spaces
		h3 "$prnPathName" / $(date +'%H:%M on %A, %B %e') / "$UUID"
		(make+run) # use subshell, don't dirty the ENVIRONMENT¹
		cksum_previous=$cksum_current
	done
} #}}}1
# ¹/ if we only ever use += and run it more than once we're adding
#    everything twice or more. For example, 
#    CFLAGS += -I.. run twice would yield CFLAGS='-I.. -I..', three
#    times CFLAGS='-I.. -I.. -I..', etc.

(($#))|| die 'Missing required argument ^Usrc^u.'
(($#==1))|| die 'Too many arguments. Expected only ^Usrc^u.'

needs h3 needs-cd rlwrap

# HANDLE VERBOSITY
typeset -l verbose=${VERBOSE:-false}
if [[ $verbose == @(no|false|0) ]]; then
	showvar_fn=:
else
	showvar_fn=first-time-get-set
fi

# HANDLE OTHERWHERE source file
filename=$1
[[ $filename == */* ]]&& {
	pathname=${filename%/*}
	filename=${filename#"$pathname/"}
	needs-cd -or-die "$pathname"
}

EXE=${filename%.c}
CFILE=$EXE.c

$MAIN; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
