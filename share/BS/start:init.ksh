#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2021-05-26,23.44.35z/249cd2d>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap
# =======================================================================
#   Set up X11 app specific start framework
#   This script is expected to be called from start.ksh
# =======================================================================

set -o errexit -o nounset;: ${FPATH:?Run from within KSH}

CFG=$XDG_CONFIG_HOME/start
SKEL_DIR=$CFG/home_template
APP_BASE=/home/apps
GRPNAME=usrapp
APP_CLASS=app
START_SCRIPT=start-app.ksh
logName='start-init-doas'
NL='
' # end of NL assignment
TAB='	'

this_pgm=${0##*/}
function usage { # {{{1
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^Uapp^u
	   Set up X11 app specific ^Tstart^t framework.
	   ^Uapp^u  The name of the command and the user that will be used to
	            run the application.

	   This script is expected to be called from ^Tstart^t, and
	   ^Bmust^b be run as ^Sroot^s.
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
	U=/usr/local/bin
	[[ -f $U/start ]]|| return 0

	[[ -f $CFG/start ]]||
		die "No ^Tstart^t script for ^B$Ub."

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

	@ "# Adding member '$USRNAME' to group '$GRPNAME'."
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
	>>login.conf sed -E -i'' -e 's/^|//' <<-\
	===
		|$APP_CLASS:\\
		|	:datasize-cur=1536M:\
		|	:datasize-max=infinity:\
		|	:maxproc-max=1024:\
		|	:maxproc-cur=384:\
		|	:ignorenologin:\
		|	:requirehome@:\
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
	D="permit nopass $USRNAME as $APP cmd /usr/local/bin/start"
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
function copy-app-starter { # {{{1

	[[ -f $USER_START ]]&&	return 0 # ~$APP/bin/$S already exists
	[[ -d $CFG/$APP ]]||	return 1 # no specialized $S exists
	[[ -f $CFG/$APP/$START_SCRIPT ]]||	return 1 # no specialized $S exists

} # }}}1
function mk-app-starter { # {{{1
	cat <<-\
		======
		#!/bin/ksh
		$(mk-stemma-header \#)
		# \vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

		typeset -i i=0
		for o; do
		    [[ -f \$o ]]&& o=file://\$o
		    opts[i++]=\$o
		done

		exec $(which -a "$APP" | egrep ^/usr/) "\${opts[@]}"
		# Copyright (C) $(date +%Y) by Tom Davis <tom@greyshirt.net>.
		======
} # }}}1
function create-app-starter { # {{{1
	local F P S

	P=$CFG/$APP
	mkdir -p "$P/RCS" || die "Cannot ^Tmkdir^t ^B$P^b."

	F=$P/$START_SCRIPT
	mk-app-starter >$F || die "Could not create ^Bstart-app.ksh^b."
	chmod a+rx "$F"

	# edit
	(set +u +e; f-v "$F" "Starter app for $APP")

} # }}}1
function create-user-links { # {{{1'
	local D

	ln -sf "$KDOTDIR/share/BS/start.ksh" "$USRBIN/$APP"

	D=$XDG_DOCUMENTS_DIR/$APP
	if mkdir -p -m 0775 "$D"; then
		warn "Could not ^Tmkdir^t ^B\$XDG_DOCUMENTS_DIR/$APP^b" ||:
	else
		chgrp "$GRPNAME" "$D"
	fi
} # }}}1
function link-as-app { @ doas -u $APP ln -sf "$1" "$APP_HOME/$2"; }
function link-from-out-into-app-home { # {{{1'

	# links are being created to not yet existent files, but that's fine
	link-as-app "$XDG_DOWNLOAD_DIR"			"Downloads"
	link-as-app "$XDG_DOCUMENTS_DIR/$APP"	"Documents"
	link-as-app "$CFG/$APP/$START_SCRIPT"	"bin/$USER_START"

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

needs shquote f-v h1

USRNAME=$(id -un)

APP=$1
APP_HOME=$APP_BASE/$APP
USER_START=$APP_HOME/bin/$START_SCRIPT

HOLD=~/hold/$(uname -r)/sys-files/etc

mkdir -p "$HOLD/RCS" >/dev/null	|| die "Could not ^Tmkdir^t ^B$HOLD^b."
builtin cd "$HOLD"				|| die "Could not ^Tcd^t to ^B$HOLD^b."

fTEMP=$(mktemp)
trap CleanUp EXIT
exec 3>$fTEMP
p3 '#!/bin/ksh'
p3 '# THIS IS AN AUTOGENERATED FILE TO CONSOLIDATE DOAS CALLS'
p3 ''
p3 'set -o errexit -o nounset -o verbose'
p3 "PS4='### '"
p3 ''
fTEXT=$(<$fTEMP)

# these actions require root privileges, so we do all testing and
# preparations and write any commands we need to run as root to a file
# so we can run `doas` once and only once.
install-usrbin-start
create-group-usrapp
add-member-to-usrapp
create-login-class
create-home-app
create-app-user
set-usrhome-modes
update-doas-conf
link-from-out-into-app-home	# links can be created to non-existent files

# run the file IF we added any commands
[[ $(<$fTEMP) != $fTEXT ]]&& {
	chmod u+x "$fTEMP"
	h1 'Running as root'
	doas "$fTEMP"
	h1 'Finished being root'
  }

builtin cd "$CFG"
copy-app-starter || create-app-starter
create-user-links 

# Copyright (C) 2021 by Tom Davis <tom@greyshirt.net>.
