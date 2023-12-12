#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2020-12-28,19.09.22z/47b5b85>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

exec 2>>~/log/dmenu_dwming.log
set -o nounset;: ${FPATH:?Run from within KSH}

cmdcache=${XDG_CACHE_HOME:-"$HOME/.cache"}/wdm-dmenu-cmds
BROWSER=$(<$XDG_CONFIG_HOME/etc/browser)

NL='
'
# dmenu_path grabs EVERY command, but we don't use most of those, so
# we're seeing tons that we don't use. And many of those are cli only,
# so those don't make sense either. Those probably need a terminal.

function list-start-apps { #{{{1
	P=/home/apps
	[[ -d $P ]]|| return
	needs-cd -or-warn "$P" || return 1
	for app in *; do
		[[ -d $app ]]&& print -rn -- "$app "
	done
} # }}}1
function list-amuse-commands { # {{{1
	amuse:env
	for a in ${AMUSE_COMMANDS:?}; do
		print -rn -- "@$a "
	done
} # }}}1
function ws-get-amazon-search  { #{{{1
	REPLY="http://smile.amazon.com/s?k=$1"
} #}}}1
function ws-get-book-search  { #{{{1
	REPLY="https://smile.amazon.com/s?k=$1&i=stripbooks"
} #}}}1
function ws-get-cpan-search  { #{{{1
	REPLY="https://metacpan.org/search?q=$1"
} #}}}1
function ws-get-google-search  { #{{{1
	a="https://www.google.com/search?hl=en&q="
	b=$1
	c="&btnG=Google+Search"
	REPLY="$a$b$c"
} #}}}1
function ws-get-imdb-search  { #{{{1
	REPLY="https://www.imdb.com/find?s=all&q=$1"
} #}}}1
function ws-get-map-search  { #{{{1
	REPLY="http://maps.google.com/maps?oi=map&q=$1"
} #}}}1
function ws-get-synonyms-search  { #{{{1
	REPLY="https://onelook.com/reverse-dictionary.shtml?s=$1"
} #}}}1
function ws-get-translate-search  { #{{{1
	a='https://translate.google.com/?hl=en&tab=wT#auto|en|'
	b=$1
	REPLY="$a$b"
} #}}}1
function ws-get-wikipedia-search { #{{{1
	REPLY="https://en.wikipedia.org/w/index.php?search=$1"
} #}}}1
function urlencode  { #{{{1
	local pgm='print uri_escape($ARGV[0])'
	REPLY=$(/usr/bin/perl -MURI::Escape -e "$pgm" "$*")
} #}}}1
function websearch  { #{{{1
	urlencode "$2"
	ws-get-$1-search "$REPLY"
} #}}}1
function browse-the-web  { #{{{1
	local scheme url
	[[ $1 == @(chrome|surf) ]] && {
		local x=$USRBIN/$1
		shift
		$x "$@"
		return
	  }

	if [[ $1 == www* ]]; then
		scheme=https
		url=www.${1##www?(.)}$2
	else
		scheme=http
		[[ $1 == https* ]]&& scheme=https
		url=${1##http?(s)}$2
		url=${url##:?(//)}
	fi

	${BROWSER:-$USRBIN/surf} "$scheme://$url"
} #}}}1
function handle-cmd { # {{{
	local cmd qARGS req args
	read -r req args
	[[ -z $req ]]&& { st & return; }

	[[ $req == ESC ]]&& return 1

	# aliases
	case $req in
		g)	req=google;				;;
		a)	req=amazon;				;;
		c)	req=cpan;				;;
		w)	req=wikipedia;			;;
		h)	req=http;				;;
		s)	req=https;				;;
		,)	req=lockdown; args=z;	;;
		wordnet)
			req=wnb;				;;
	esac


# websearch
	[[ " $websearch " == *" $req "* ]]&& {
		websearch "$req" "$args"
		$BROWSER "$REPLY"
		return
	  }

	[[ $req == @(http?(s)|www)* ]]&& {
		browse-the-web "$req" "$args"
		return
	  }

# special
	[[ $req == amuse || $req == amuse-ui ]]&& {
		in-new-term amuse-ui
		return
	  }

	shquote "$args" qARGS
	if [[ $req == !* ]]; then
		cmd="${req#!*( )} $qARGS"
	elif [[ $req == ,* ]]; then
		cmd="lockdown z"
	elif [[ " $newterm " == *" $req "* ]]; then
		[[ $req == in-new-term ]]|| cmd='in-new-term '
		cmd="${cmd:-}$req $qARGS"
	elif [[ " $starts " == *" $req "* ]]; then
		cmd="start $req $qARGS"
	elif [[ " $amuse " == *" $req "* ]]; then
		cmd="amuse:send-cmd ${req#@}"
	elif [[ " $others $web $x11 " == *" $req "* ]]; then
		cmd="$req $qARGS"
	else
		local msg='Unknown `dmenu_dwming` Command'
		cmd="Xdialog --title '$msg' --msgbox '$msg$NL$req '$qARGS 0 0"
	fi
	ksh -c "$cmd" &
} # }}}1

needs amuse:env dmenu dwm_dmenu_completion grep in-new-term sort

starts=$(list-start-apps)
amuse=$(list-amuse-commands)
websearch='g a w amazon book cpan google imdb map synonyms translate wikipedia'
x11='display ghb glxgears oclock showrgb soffice xcalc xclock xmag xwd'
others='amuse weather wordnet wnb'
web='h s http https www chrome surf'
special=	# 'task'
newterm='man in-new-term'

# dypgm=dwm_dmenu_completion

[[ -n ${DEBUG:-} ]]&& {
	print -u2 -- "===== SUPPORTED COMMANDS ====="
	print -u2 -- "  starts:    $starts"
	print -u2 -- "  websearch: $websearch"
	print -u2 -- "  others:    $others"
	print -u2 -- "  x11:       $x11"
	print -u2 -- "  amuse:     $amuse"
	print -u2 -- "  web:       $web"
	print -u2 -- "  special:   $special"
	print -u2 -- "  newterm:   $newterm"
	print -u2 -- "=============================="
  }

[[ $cmdcache -ot $0 ]]&&
	for w in '' $starts $websearch $others $x11 $amuse $web $special $newterm; do
		print -r -- "$w";
	done | sort --unique >$cmdcache

# { dmenu -dy "$dypgm '$cmdcache'" "$@" || print "ESC"; } | handle-cmd
{ dmenu "$@" <$cmdcache || print "ESC"; } | handle-cmd; exit


# Copyright (C) 2020 by Tom Davis <tom@greyshirt.net>.
