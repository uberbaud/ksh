#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2021-01-01,01.37.19z/8e8b31>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}


[[ $# -eq 0 || $1 == -h ]]&& { # {{{1
	print -ru2 -- \
		"${0##*/}: Handle -dy additionaly completion stages."
	exit 0
} # }}}1

cmdcache=$1; shift
[[ -f $cmdcache ]]|| exit 1

(($#))|| { print -r -- "$(<$cmdcache)"; exit; }

scriptpath=${XDG_CONFIG_HOME:-~/config}/dwm/dy-scripts
cmd=$scriptpath/$1.ksh
[[ -x $cmd ]]&& $cmd "$@"

# Copyright (C) 2021 by Tom Davis <tom@greyshirt.net>.
