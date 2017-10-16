#!/bin/ksh
# @(#)[:aXvz$y=Px4oEjA;-81a_: 2017-08-15 17:58:56 Z tw@csongor]
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

: ${FPATH:?}

realbin="$(realbin $0)"
shortcall="${0##*/}"; shortcall="${shortcall%.*}"
shortbin="${realbin##*/}"; shortbin="${shortbin%.*}"
app=''
if [[ $shortcall != $shortbin ]]; then
	app="${shortcall#start-}"
else
	# Usage {{{1
	typeset -- this_pgm="${0##*/}"
	function usage {
		desparkle "$this_pgm"
		PGM="$REPLY"
		sparkle >&2 <<-\
		===SPARKLE===
		^F{4}Usage^f: ^T${PGM}^t
		         Starts an X11 app with specialized settings.
		         Calling a link named ^Tstart-^B^UAPP^u^b^t or just ^T^B^UAPP^u^b^t
		           has the same effect as calling ^Tstart ^UAPP^u^t.
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
	shift $(($OPTIND - 1))
	# ready to process non '-' prefixed arguments
	# /options }}}1
	(($#))|| die 'Missing required parameter ^Uapp-name^u.'
	app="$1"
	shift
fi

strtcfg=${XDG_CONFIG_HOME:?}/start
[[ -d $strtcfg ]]|| mkdir -p "$strtcfg"
[[ -d $strtcfg ]]|| die 'No ^B$XDG_CONFIG_HOME/start^b directory.'

appcfg="$strtcfg/$app.ini"
appbin="$(which "$app" 2>/dev/null)"
desparkle "$app"; d_app="$REPLY"
[[ -n $appbin ]]|| {
	[[ -f $appcfg ]]||
		die "No executable nor config file for ^Bd_app^b."
  }

needCfgFile=false
[[ -f $appcfg ]]|| {
	warn "No configuration file ^B\$XDG_CONFIG_HOME/start/$d_app.ini^b."
	yes-or-no Continue || exit 1
	needCfgFile=true
  }

REALHOME="$HOME"
HOME="$XDG_DATA_HOME/run/$app"
[[ -d $HOME ]]|| mkdir -p "$HOME"
cd "$HOME" || die "Could not ^Tcd^t to ^B$HOME^b."
[[ -d $HOME/log ]]|| mkdir -p $HOME/log

[[ -f .Xauthority ]]||	ln -s "$REALHOME/.Xauthority" || die 'Bad .Xauthority'
[[ -d rxfer ]]||		ln -s "$REALHOME/rxfer"

XDG_DOCUMENTS_DIR="$XDG_DOCUMENTS_DIR/$app"
[[ -d $XDG_DOCUMENTS_DIR ]]||	mkdir -p "$XDG_DOCUMENTS_DIR"
[[ -d docs ]]|| ln -s "$XDG_DOCUMENTS_DIR" docs

function mkCfgFile { # {{{1
	notify "Creating configuration file ^B\$XDG_CONFIG_HOME/start/$d_app.ini^b."
	cat >"$appcfg" <<-\
	---
	; $(mk-stemma-header)
	; vim: ft=dosini
	; start ${app} configuration

	desktop=xApp
	appbin=$appbin
	; uncomment below to prevent multiple invocations
	;oneinstance

	; all shell special characters in environment assignment will be escaped.
	; Enviroment variables are available in any following sections.
	[environment]

	; directory & file are TARGET=SOURCE where
	;   TARGET is rooted in \$XDG_DATA_HOME/run/$app, and
	;   SOURCE is rooted in \$HOME
	; If there is no =SOURCE, SOURCE has the same name as TARGET.
	; !TARGET (exclamation mark, no =SOURCE) means mkdir
	;   (not available for file).
	[directory]
	[file]
	[prefix-args]
	[suffix-args]

	---
} # }}}1
function badcfg { #{{{1
	[[ $appcfg == ${XDG_CONFIG_HOME}/* ]]&& appcfg=\$XDG_CONFIG_HOME${appcfg#$XDG_CONFIG_HOME}
	[[ $appcfg == ${HOME}/* ]]&& appcfg=\$HOME$Pappcfg#$HOME}
	desparkle "$appcfg"
	die "$@" "file: ^S$REPLY^s" "line $LNO: ^T$ln^t"
} #}}}1
dskBROWSER=${dskBROWSER:-1}; dskXAPP=${dskXAPP:-6}; dskWIDGET=${dskWIDGET:-7}
function optcmd-general { #{{{1
	typeset -u deskvar
	case "$1" in
		desktop)		deskvar="$2"; eval desktop="\$dsk$deskvar";	;;
		oneinstance)	oneInstance=true;							;;
		appbin)			appbin="$2";								;;
		# UNKNOWN
		*) badcfg "Unknown configuration directive:" "$1=$2";		;;
	esac
} # }}}1
function optcmd-fsobject { # {{{1
	typeset -- TRG="$HOME/$1" t="-${3%${3#?}}" fsType="$3"
	desparkle "$1"; typeset -- d_1="$REPLY"
	desparkle "$2"; typeset -- d_2="$REPLY"

	[ $t "$TRG" ]&& return 0 # use […] to expand $t, [[…]] won't
	[[ -e $TRG ]]&& badcfg "^B$1^b exists but is not a ^B$fsType^b."

	[[ $TRG == \!* ]]&& {
		[[ $t == '-d' ]]|| badcfg 'Only directories can be created.'
		mkdir -p "$HOME/${TRG#?}"
		return $?
	  }
	typeset -- SRC="$(readlink -f "${REALHOME}/$2")"
	[[ -n $SRC ]]|| return 1

	if [ $t "$SRC" ]; then
		if [[ $SRC == $REALHOME/.* ]]; then
			warn "Moving ^B$2^b from ^S\$HOME^s to ^S\$XDG_DATA_HOME/run/$d_app^s."
			mv "$SRC" "$TRG" ||
				badcfg "Could not ^Tmv^t $d_2 to $d_1."
		else
			ln -s "$SRC" "$TRG" ||
				badcfg "Could not link ^B$d_2^b to ^B$d_1^b."
		fi
	elif [[ -e "$SRC" ]]; then
		badcfg "^B$d_1^b exists but is not a ^B$fsType^b."
	fi
} # }}}1
function optcmd-prefix-args	{ prefixArgs[${#prefixArgs[*]}]="$1${2:+\=$2}"; }
function optcmd-suffix-args	{ suffixArgs[${#suffixArgs[*]}]="$1${2:+\=$2}"; }
function optcmd-directory	{ optcmd-fsobject "$1" "${2:-$1}" directory; }
function optcmd-file		{ optcmd-fsobject "$1" "${2:-$1}" file; }
function optcmd-environment	{ # {{{1
	(($#==2))||
		badcfg 'Bad environment variable declaration.'
	desparkle "$1"; typeset -- d_1="$REPLY"
	desparkle "$2"; typeset -- d_2="$REPLY"
	[[ $1 == [A-Za-z_]*([A-Za-z0-9_]) ]]||
		badcfg "Bad environment variable name ^B$_2^b."
	eval "export $1=$2" ||
		badcfg "Could not export ^B$d_1^b as ^B'$d_2'^b."
	eval setto="\$$1"
	[[ $2 == $setto ]]||
		badcfg "Could not use ^B$d_2^b as a value."
} # }}}1

oneInstance=false
if $needCfgFile; then
	mkCfgFile
else
	desktop=0
	docmd='general'
	validcmds=' general directory file environment prefix-args suffix-args '
	integer LNO=0
	splitstr NL "$(<$appcfg)" cfglines
	for ln in "${cfglines[@]}"; do
		((LNO++))
		# COMMENTS & BLANK LINES
		[[ $ln == \;* ]]&&				continue
		[[ $ln == \#* ]]&&				continue
		[[ -z $ln ]]&&					continue
		[[ $ln == *([[:space:]]) ]]&&	continue
		# HEADING
		[[ $ln == \[*\] ]]&& {
			docmd="${ln#\[}"; docmd="${docmd%\]}"
			[[ $validcmds == *" $docmd "* ]]||
				badcfg 'Unknown category in ini file.'
			continue
		  }
		# SETTING
		[[ $ln == =* ]]&& badcfg 'Missing key name'
		key="${ln%%=*}"
		val="${ln#$key}"; val="${val#=}"
		[[ $key == 'if('*'):'* ]]&& {
			tmpvar="$key${val:+\=$val}"
			test="${key#if\(}"; test="${test%\):*}"
			if [[ $test == '$#' ]]; then
				(($#))|| continue
			elif [[ $test == '!$#' ]]; then
				(($#))&& continue
			else
				desparkle "$test"
				badcfg "Unknown test: ^Tif(^B$REPLY^b)^t"
			fi
			tmpvar="${tmpvar#if(*):}"
			key="${tmpvar%%=*}"
			val="${tmpvar#$key}"; val="${val#=}"
		}

		optcmd-$docmd "$key" "$val"
	done
	set -- "${prefixArgs[@]}" "$@" "${suffixArgs[@]}"
fi

[[ "$(readlink -nf $appbin)" == $realbin ]]&& {
	local x='' possibles
	set -A possibles -- $(which -a "$app")
	local errmsg="^B$appbin^b is masked by wrapper to ^Bstart^b."
	function _ {
		for x in "${possibles[@]}"; do
			[[ "$(readlink -nf "$x")" != $realbin ]]&& return
		done
		die "$errmsg" \
			"Could not find a suitable executable named: ^B$d_app^b."
	}; _; unset -f _
	app=$x
	warn "errmsg" "Using ^B$d_app^b instead."
}

# switch to the requested desktop
needs "$appbin"
((desktop))&& {
	needs xdotool
	xdotool set_desktop $desktop
}

# don't start a new process if we're not supposed to.
$oneInstance && {
	pgrep -q "^${appbin##*/}$" && {
		notify 'Already running'
		exit 0
	  }
}

# and finally, start it up!
print "$appbin $*" > log/$$ 2>&1 &
nohup "$appbin" "$@" >> log/$$ 2>&1 &
mv log/$$ log/$!

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
