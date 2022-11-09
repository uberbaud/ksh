#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2021-05-26,23.44.35z/249cd2d>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap
# =======================================================================
#   Set up X11 app specific start framework
#   This script is expected to be called from start.ksh
# =======================================================================

set -o errexit -o nounset;: ${FPATH:?Run from within KSH}

KEEPENVS='AUDIODEVICE DBUS_SESSION_BUS_ADDRESS START_OPTIONS'
AUTHOR='Tom Davis <tom@greyshirt.net>'
CFG=$XDG_CONFIG_HOME/start
PUB=$HOME/public/start
SKEL_DIR=$CFG/home_template
APP_BASE=/home/apps
GRPNAME=usrapp
APP_CLASS=app
START_SCRIPT=start-app.ksh
STARTER_BIN=/usr/local/bin/start
logName='start-init-doas'
NL='
' # end of NL assignment
TAB='	'

this_pgm=${0##*/}
function usage { # {{{1
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^Uapp^u
	   Set up X11 app specific ^Tstart^t framework.
	   ^Uapp^u  The name of the command and the user that will be used to
	            run the application.

	   This script is expected to be called from ^Tstart^t.
	===SPARKLE===
	exit 0
} # }}}
function @ { # {{{1'
	if [[ ${1:---} == -- ]]; then
		print -ru3 # blank line
	else
		local W
		shquote "$1"
		print -nru3 -- "$REPLY"
		shift
		for W; do
			shquote "$W"
			print -nru3 -- " $REPLY"
		done
		print -u3
	fi
} # }}}1
function p3 { print -ru3 -- "$*"; }
function hold_initialize { # {{{1
	notify "Verifying and updating hold copy of ^B$1^b."

	[[ -f /etc/$1 ]]|| die "No such file ^B$1^b."
	if [[ -f $1 ]]; then
		rcsdiff -q "$1" >/dev/null ||
			ci -q -j -m"$this_pgm: save ./" -u "$1"
	elif [[ -f RCS/$1,v ]]; then
		co -q "$1"
	else
		cp /etc/"$1" .
		ci -q -i -t-'OpenBSD system file' -u "$1"
	fi

	# ensure we have the current copy
	diff -q {/etc/,}"$1" >/dev/null 2>&1 || {
		co -q -l "$1"
		cp /etc/"$1" .
		ci -q -j -m"$this_pgm: save /etc/" -u "$1"
	  }

	co -q -l "$1"
} # }}}1
function hold_ci { # {{{1
	notify "RCS check-in of ^S\$HOLD^s/^B$1^b"
	ci -q -j -m"$this_pgm: Add start-app specific bits" -u "$1"
} # }}}1
function install-usrbin-start { # {{{1
	local U

	[[ -f $STARTER_BIN ]]&& return 0

	U=${STARTER_BIN%/*}
	[[ -f $CFG/start ]]||
		die "No ^Tstart^t script for ^B$U^b."

	@ install -o root -g bin -m 755 "$CFG/start" "$U"
} # }}}1
function create-group-usrapp { # {{{1'
	groupinfo -e "$GRPNAME" && return

	# @ --
	# @ h1 "Adding group $GRPNAME"
	@ groupadd -v "$GRPNAME"
} # }}}1
function add-member-to-usrapp { # {{{1'
	[[ $(getent group usrapp) == *[:,]$USRNAME*(,+([!;])) ]]&& return

	# @ h1 "Adding member <$USRNAME> to group <$GRPNAME>."
	@ usermod -G "$GRPNAME" "$USRNAME"
} # }}}1
function p3_copy_hold { # {{{1
	# @ --
	# @ h1 "Adding $1 to /etc/$2."
	@ cp {"$PWD",/etc}/"$2"
} # }}}1
function create-login-class { # {{{1
	egrep -q "^$APP_CLASS:" /etc/login.conf && return 0

	hold_initialize login.conf
	# we can't just cat because we need those tabs
	>>login.conf sed -E -e 's/^\|//' <<-\
	===
		|$APP_CLASS:\\
		|	:datasize-cur=1536M:\\
		|	:datasize-max=infinity:\\
		|	:maxproc-max=1024:\\
		|	:maxproc-cur=384:\\
		|	:ignorenologin:\\
		|	:requirehome@:\\
		|	:tc=default:
	===
	hold_ci login.conf

	p3_copy_hold 'class app' login.conf
} # }}}1
function create-home-app { # {{{1
	[[ -d $APP_BASE ]]&& return

	# @ --
	# @ h1 "Create $APP_BASE"
	@ mkdir -m 0775 "$APP_BASE"
} # }}}1
function create-app-user { # {{{1
	userinfo -e "$APP" && return

	[[ -d $SKEL_DIR ]]||
		die 'No template for creating home directories.'

	local opt
	typeset -i i=0

	# using template $SKEL_DIR
	opt[i++]=-k
	opt[i++]=$SKEL_DIR

	# create home directory in $APP_BASE
	opt[i++]=-b
	opt[i++]=$APP_BASE
	opt[i++]=-m

	# set the group
	opt[i++]=-g
	opt[i++]=$GRPNAME

	# with login class
	opt[i++]=-L
	opt[i++]=$APP_CLASS

	# GECOS/comment field
	opt[i++]=-c
	opt[i++]="Start user for $APP"

	# @ --
	# @ h1 "Create user '$APP'."
	@ useradd -v "${opt[@]}" "$APP"
} # }}}1
function update-doas-conf { # {{{1'
	local D A a B
	D="permit nopass setenv { $KEEPENVS } $USRNAME as $APP cmd $STARTER_BIN"
	egrep -q "^$D\$" /etc/doas.conf && return

	hold_initialize doas.conf

	A='# apps'
	a="^$A\$"
	B=f
	egrep -q "$a" /etc/doas.conf || {
		notify 'Appending comment/header to ^Bdoas.conf^b.'
		sed -E -i'' -e "\$a\\$NL$A\\$NL" doas.conf
	  }

	notify "Adding ^B$APP^b permission to ^Bdoas.conf^b."
	sed -E -i'' -e "/$a/a\\$NL$D\\$NL" doas.conf

	hold_ci doas.conf

	p3_copy_hold 'permissions' doas.conf
} # }}}1
function set-usrhome-modes { # {{{1
	@ chmod -R g+w $APP_HOME/{Public,bin,log,media}
} # }}}1
function skelout { # {{{1
	cat <<-\
	======
		#!/bin/ksh
		$(mk-stemma-header \#)
		# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

		typeset -i i=0
		for o; do
		    [[ -f \$o ]]&& o=file://\$o
		    opts[i++]=\$o
		done

		exec $(which -a "$APP" | egrep ^/usr/) "\${opts[@]}"
		# Copyright (C) $(date +%Y) by $AUTHOR.
	======
} # }}}1
function mk-app-starter { # {{{1
	[[ -f $USER_START ]]&& return 0 # ~$APP/bin/$S already exists
	needs-path -create -or-warn "$PUB/$APP" || return
	[[ -s $1 ]]&& return 0 # specialized $S already exists

	skelout >$1 || {
		warn 'Could not write app-starter.'
		return
	  }

	chgrp usrapp "$1" || warn "Could not set group on ^S$1^s."
	chmod g+rx "$1" &&
		ci -u -i -t"-Start $APP as its own user in <$GRPNAME> group"  "$1"

} # }}}1
function edit-start-script { # {{{1
	local P=${1:?} F=${2:?}
	needs-cd -or-die "$P"
	[[ -d RCS ]]|| mkdir RCS
	[[ -f RCS/$F,v ]]||
		ci -q -u -i -t-"Starter app for $APP" "$F"
	co -q -l "$F"
	${VISUAL:-${EDITOR:-vi}} "$F"
	ci -q -u "$F"
} # }}}1
function create-app-starter { # {{{1
	local F P S

	P=$PUB/$APP
	needs-path -create -or-die "$P/RCS"

	
	mk-app-starter "$P/$START_SCRIPT" ||
		die "Could not create ^Bstart-app.ksh^b."
	(edit-start-script "$P" "$START_SCRIPT")

} # }}}1
function copy-file { # {{{1
	local src dst pDst fDst

	src=${1:?'Missing _src_ parameter (1) to `copy-file`.'}
	dst=${2:?'Missing _dst_ parameter (2) to `copy-file`.'}

	[[ $dst == $APP_HOME/* ]]||
		warn "^Tcopy-file^t destination is not ^B$APP_HOME^b."

	fDst=${dst##*/}
	pDst=${dst%"$fDst"}
	! [[ -z $pDst || -d $pDst ]]&&
		@ mkdir -p "$pDst"
	@ cp "$src" "$dst"
	@ chown -R $APP:$GRPNAME "$pDst"

} # }}}1
function create-auth-files { # {{{1
	local F
	F=.sndio/cookie # sharing a cookie allows applications to share access
					# to sndio, otherwise only one user's app can play
					# sound at a given time.
	copy-file $HOME/$F $APP_HOME/$F
} # }}}1
function create-user-links { # {{{1
	local D

	ln -sf "$KDOTDIR/share/BS/start.ksh" "$USRBIN/$APP"

	D=$XDG_DOCUMENTS_DIR/$APP
	needs-path -create -or-false "$D" || return

	[[ $(stat -f %Sg "$D") == $GRPNAME ]]||
		chgrp -R $GRPNAME "$D" ||
			warn "Could not ^Tchgrp -R^t ^B\$XDG_DOCUMENTS_DIR/$APP^b"

	[[ $(stat -f %Lp "$D") == 775 ]]||
		chmod -R 0755 "$D" ||
			warn "Could not ^Tchmod -R^t ^B\$XDG_DOCUMENTS_DIR/$APP^b"

	return 0	# if we got it created, let that be enough to continue for
				# the moment, we'll sort it out later.
} # }}}1
function link-as-app { # {{{1
	[[ -a $2 ]]&& return 0 # it exists, nothing to do
	@ doas -u $APP ln -sf "$1" "$2"
} # }}}1
function link-from-out-into-app-home { # {{{1'

	# links are being created to not yet existent files, but that's fine
	link-as-app "$XDG_DOWNLOAD_DIR"			"$APP_HOME/Downloads"
	link-as-app "$XDG_DOCUMENTS_DIR/$APP"	"$APP_HOME/Documents"
	link-as-app "$PUB/$APP/$START_SCRIPT"	"$USER_START"

} # }}}1
function CleanUp { # {{{1'
	exec 3>&-
	date +"=== $logName: %Y-%m-%d %H:%M:%S %z ==="	|
		cat - "$fTEMP" >>~/log/$logName.log
	rm "$fTEMP"
} # }}}1

[[ -d $SKEL_DIR ]]|| die "No skeleton directory ^B$SKEL_DIR ^b."
(($#))||	die 'Missing required arguments'
(($#>1))&&	die 'Too many arguments. Expected one (1).'
[[ $1 == -h ]]&& usage

needs shquote f-v h1 needs-cd needs-path

USRNAME=$(id -un)

APP=$1
APP_HOME=$APP_BASE/$APP
USER_START=$APP_HOME/bin/$START_SCRIPT

HOLD=~/hold/$(uname -r)/sys-files/etc

function main {
	needs-path -create -or-die "$HOLD/RCS"
	needs-cd -or-die "$HOLD"

	fTEMP=$(mktemp)
	trap CleanUp EXIT
	notify "generating $fTEMP," "which will be saved to log ~/log/$logName.log"
	exec 3>$fTEMP
	p3 '#!/bin/ksh'
	p3 '# THIS IS AN AUTOGENERATED AND TEMPORARY FILE'
	p3 '#   WRITTEN AND USED BY start:init.ksh TO CONSOLIDATE DOAS CALLS'
	p3 ''
	p3 'set -o errexit -o nounset -o verbose'
	p3 "PS4='### '"
	p3 ''
	fTEXT=$(<$fTEMP)

	# these actions require root privileges, so we do all testing and
	# preparations and write any commands we need to run as root to 
	# a file so we can run `doas` once and only once.
	install-usrbin-start
	create-group-usrapp
	add-member-to-usrapp
	create-login-class
	create-home-app
	create-app-user
	set-usrhome-modes
	update-doas-conf

	link-from-out-into-app-home

	# run the file IF we added any commands
	[[ $(<$fTEMP) != $fTEXT ]]&& {
		chmod u+x "$fTEMP"
		h1 'Running as root'
		doas "$fTEMP"
		h1 'Finished being root'
  	}

	create-app-starter
	create-user-links

}

main "$@"; exit

# Copyright (C) 2021 by Tom Davis <tom@greyshirt.net>.
