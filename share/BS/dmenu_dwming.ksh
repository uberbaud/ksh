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
	b="$1"
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
	b="$1"
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
	local cmd
	read -r req args
	[[ -z $req ]]&& { st & return; }

	[[ $req == ESC ]]&& return 1

	case $req in
		g)	req=google;		;;
		a)	req=amazon;		;;
		c)	req=cpan;		;;
		w)	req=wikipedia;	;;
		h)	req=http;		;;
		s)	req=https;		;;
		wordnet)
			req=wnb;		;;
	esac

	[[ " $websearch " == *" $req "* ]]&& {
		websearch "$req" "$args"
		surf "$REPLY"
		return
	  }

	[[ $req == @(http?(s)|www)* ]]&& {
		browse-the-web "$req" "$args"
		return
	  }

	shquote "$args" # => REPLY
	if [[ $req == !* ]]; then
		cmd="${req#!*( )} $REPLY"
	elif [[ $req == ,* ]]; then
		cmd=", z"
	elif [[ " $starts " == *" $req "* ]]; then
		cmd="start $req $REPLY"
	elif [[ " $others $x11 " == *" $req "* ]]; then
		cmd="$req $REPLY"
	else
		local msg='Unknown `dmenu_dwming` Command'
		cmd="Xdialog --title '$msg' --msgbox '$msg$NL$req '$REPLY 0 0"
	fi
	ksh -c "$cmd" &
} # }}}1

needs dmenu dwm_dmenu_completion grep sort
starts=''
for n in ${XDG_CONFIG_HOME:-~/config}/start/*.ini; do
	n=${n##*/}
	n=${n%.ini}
	starts="$starts $n"
done
amuse=$(functions + | grep ^@)
websearch='g a w amazon book cpan google imdb map synonyms translate wikipedia'
x11='display ghb glxgears oclock showrgb soffice xcalc xclock xmag xwd'
others='amuse weather wordnet wnb'
web='h s http https www chrome surf'
special='task'

dypgm=dwm_dmenu_completion

for w in '' $starts $websearch $others $x11 $amuse $web $special; do
	print -r -- "$w";
done | sort >$cmdcache

{ dmenu -dy "$dypgm '$cmdcache'" "$@" || print "ESC"; } | handle-cmd


# Copyright (C) 2020 by Tom Davis <tom@greyshirt.net>.
