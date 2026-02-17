#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2022-05-17,20.16.23z/461e7f5>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

trap 'print -u2 -- "  SIGHUP"'  HUP
trap 'print -u2 -- "  SIGINT"'  INT
trap 'print -u2 -- "  SIGTSTP"' TSTP
trap 'print -u2 -- "  SIGINFO"' INFO
trap 'print -u2 -- "  SIGQUIT"' QUIT

NL='
'
# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-e^t^|^T-l^t^] ^Usrc^u
	         Uses header information in C file to set build environment,
	         runs ^Tfuddle^t ^O\${^o^Vsrc^v^O%^o^T.c^t^O}^o, and runs the resulting executable.
	         ^T-l^t  Do make+run on changes to ^Usrc^u (eg: saves).
	         ^T-e^t  Open ^Usrc^u in an editor and do make+run on saves.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
MAIN=make+run
DOEDIT=false
while getopts ':elh' Option; do
	case $Option in
		e)	DOEDIT=true; MAIN=loop;											;;
		l)	MAIN=loop;														;;
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
function edit-c-file { #{{{1
	local E F T Cmd2 N AllCmds
	trap 'print -r -- edit-c-file' INT HUP QUIT TSTP
	shquote "$1" F
	integer i=0
	#Cmds[i++]='trap "" INT HUP QUIT TSTP'
	#Cmds[i++]='stty isig ignbrk -brkint'
	Cmds[i++]="${VISUAL:-${EDITOR:-vi}} $F"
	# doesn't really matter where TRACKFILE is in the command stack as 
	# long as the file $F exists when it's called.
	[[ $F == */cache/* ]]|| Cmds[i++]="trackfile $F"
	[[ -e RCS/$F,v ]]&& {
		co -l -q -f "$F"
		T=$(mktemp)
		Cmds[i++]="rcsdiff '$F'"
		Cmds[i++]="rlwrap -s 0 cat-to-file -p 'ci> ' '$T'"
	  }

	# For some reason, ci before kill makes kill not work
	Cmds[i++]='pkill -HUP -lf -- "^watch-file -i $UUID"'

	[[ -e RCS/$F,v ]]&& {
		if [[ -f $T ]]; then
			Cmds[i++]="ci -u -q -m\"\$(<$T)\" '$F'"
			Cmds[i++]="rm '$T'"
		else
			Cmds[i++]="ci -u -q -m'build-and-run' '$F'"
		fi
	  }

	AllCmds=$(IFS=\;; print -r -- "${Cmds[*]}")
	print -r -- "${X11TERM:-xterm} -e ksh -c \"$AllCmds\"" >LOG
	N=/dev/null
	(setsid ${X11TERM:-xterm} -e ksh -c "$AllCmds" &) >$N 2>&1 <$N
} #}}}1
function make+run { # {{{1
	local T rc
	h3 "fuddle >> $EXE"
	fuddle $TARGETS "$CFILE" || return

	[[ -f obj/$EXE ]]&& EXE=obj/$EXE
	if [[ -x $EXE ]]; then
		h3 "running $EXE"

		#----------------------------------------------------------------
		#  COMPLICATED REDIRECTION AHEAD
		#----------------------------------------------------------------
		# We're duping STDOUT and STDERR so, through redirection in the
		# inner subshell, we can undo the redirections of the outer
		# subshell, and thus avoid capturing the output of `$EXE`.
		#
		# We're redirecting STDERR in the outer subshell so we can
		# capture the output of `time` as explained in KSH(1).
		#
		# We close both of the dups in that innermost subshell because
		# we don't need them and potentially `$EXE` might be looking to
		# do something with them if we leave them open.

		8>&1 9>&2 T=$( (time ./"$EXE" "$@" 1>&8 2>&9 8>&- 9>&-) 2>&1)

		h3 "$EXE completed // rc = $?"
		eval $(resize)
		typeset -L$COLUMNS L=' '
		print -u2 -- "\033[48;5;238;36m$L\r$T\033[39;49m"
	elif [[ -a $EXE ]]; then
		warn "Weirdly, ^B$EXE^b is not executable."
	else
		warn "^Tmake^t completed successfully, but cannot find ^B$EXE^b."
	fi
} # }}}1
function clear-screen { print -u2 '\033[H\033[2J\033[3J\033[H\c'; }
function do-watch { # {{{1
	local uuid short

	[[ -s $fWATCH_LST ]]&&
		set -- $(<$fWATCH_LST)

	(($#))|| {
		# use full path because make may be working from elsewhere
		set -- $(realpath "$CFILE") ||
			die "Could not ^Trealpath^t ^B$CFILE^b."
	  }

	short=
	for f { short=${short:+$short }${f##*/}; }
	h2 "watching: $short"
	CHANGED=$(watch-file -i "$UUID" -v "$@")
} # }}}1
function init-fWATCH_LST { # {{{1
	local c w

	# from fuddle makefile
	# WLST = \$(.CURDIR)/${WATCHDIR:-w}/$target.wlst

	c=$(realpath .) || die "^WWeirdly^w, could not ^Trealpath .^t"

	w=$c/${WATCHDIR:-w}
	needs-path -create -or-die "$w"
	fWATCH_LST=$w/$EXE.wlst

	# fuddle [make args] source
	fuddle watchlist "$CFILE"

} # }}}1
function loop { #{{{1
	local cksum_previous cksum_current UUID

	needs cat-to-file fuddle shquote subst-pathvars
	needs pkill setsid uuid watch-file

	subst-pathvars "$PWD" prnPathName

	UUID=$(uuid) # so edit-c-file can signal ONLY THIS watch-file
	$DOEDIT && (edit-c-file "$CFILE" &)
	cksum_previous=unedited

	init-fWATCH_LST

	h3 "$prnPathName / $UUID"

	TARGETS="watchlist $EXE"
	while do-watch; do
		[[ -f $CFILE ]]|| break
		[[ ${CHANGED##*/} == $CFILE ]]&& {
			# clear on unchanged only if changed file is CFILE
			cksum_current=$(cksum "$CFILE")
			[[ $cksum_current == $cksum_previous ]]&& clear-screen
			cksum_previous=$cksum_current
		  }
		# date is outside quotes to eliminate extra spaces
		h3 "$prnPathName" / $(date +'%H:%M on %A, %B %e') / "$UUID"
		make+run "$@"
	done
} #}}}1

(($#))|| die 'Missing required argument ^Usrc^u.'

needs h3 needs-cd rlwrap needs-path

# HANDLE VERBOSITY
typeset -l verbose=${VERBOSE:-false}
if [[ $verbose == @(no|false|0) ]]; then
	showvar_fn=:
else
	showvar_fn=first-time-get-set
fi

# HANDLE OTHERWHERE source file
filename=$1; shift
[[ $filename == */* ]]&& {
	pathname=${filename%/*}
	filename=${filename#"$pathname/"}
	needs-cd -or-die "$pathname"
}

EXE=${filename%.c}
CFILE=$EXE.c

TARGETS=$EXE
$MAIN "$@"; exit

# Copyright (C) 2022 by Tom Davis <tom@greyshirt.net>.
