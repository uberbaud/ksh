#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2021-05-26,00.51.28z/23242a3>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

realbin=$(realbin "$0")
shortcall=${0##*/};       shortcall=${shortcall%.*}
shortbin=${realbin##*/};  shortbin=${shortbin%.*}
appUser=''
dPublic=${XDG_PUBLICSHARE_DIR:?}

typeset -- this_pgm=${0##*/}
function usage { # {{{1
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t
	         Per X11 app OS user start system
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
function app-framework-exists { # {{{1
	# does the app's user exist?
	getent passwd "$1" >/dev/null || {
		warn "No user with the name ^B$1^b."
		return 1
	  }

	# does the app's HOME directory exist?
	[[ -d /home/apps/$1 ]]|| {
		warn "^S\$HOME^s does not exist for ^B$1^b."
		return 2
	  }

	# does the app's start-app wrapper exist?
	[[ -f /home/apps/$1/bin/start-app.ksh ]]|| {
		warn "^S~$1/bin/start-app.ksh^s does not exist."
		return 3
	  }

	return 0
} # }}}1
function setup-app-framework { # {{{1
	desparkle "$1"
	warn "^B$REPLY^b is not set up for ^Tstart^t."

	yes-or-no "Create the framework for $REPLY" ||
		return 1

	/home/tw/config/ksh/share/BS/start:init.ksh "$1"
} # }}}1
function mktempdir { # {{{1
	local d
	d=$(date +'%Y%m%d') ||
		die 'Could not ^Tdate^t'
	t=$(mktemp -qd ~/public/tmp/"${appUser:?}-$d-XXXXXX") ||
		die 'Could not ^Tmktemp^t'
	sparkle-path "$t"
	notify "Moving files to: $REPLY."
	print -r -- "$t"
} # }}}1
function publicify-files { # {{{1
	local i a t
	# move files as necessary to a publicly accessible place.
	i=0
	for a; do
		# if it's a file but not in the public directory
		if [[ -a $a && $a != ~/public/* ]]; then
			f=${t:="$(mktempdir)"}/${a##*/}
			cp "$a" "$f" || die "Could not ^Tcp^t ^B$a^b."
			o[i++]=$f
		else
			o[i++]=$a
		fi
	done
	# make sure everything supposedly accessible is
	[[ -d ${t:-} ]]&& {
		chgrp -R usrapp "$t"	# mark the directory AND everything it contains
		chmod -R g+wr "$t"		# mark the directory AND everything it contains
		chmod g+x "$t"			# mark ONLY the directory browsable
	}
} # }}}1
needs die notify sparkle-path warn

if [[ $shortcall != $shortbin ]]; then
	appUser=${shortcall#start-}
elif [[ ${1-} == +(-)h?(elp) ]]; then
	usage
else
	(($#))|| die 'Missing required parameter ^Uapp-name^u.'
	appUser=$1
	shift
fi

app-framework-exists "$appUser" ||
	setup-app-framework "$appUser" || die "Cannot run ^T$REPLY^t."

xauth list $DISPLAY		>/home/apps/xauth-add
print -r -- "$DISPLAY"	>/home/apps/display
print -r -- "$(<~/.sndio/cookie)" >/home/apps/sndio

(($#))&& { publicify-files "$@"; set -- "${o[@]}"; }

[[ -n ${PGM_OPTIONS-} ]]&& print -- "$PGM_OPTIONS"
exec doas -u "$appUser" /usr/local/bin/start "$@"

# Copyright (C) 2021 by Tom Davis <tom@greyshirt.net>.
