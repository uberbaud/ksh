#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2019-07-29,21.39.17z/1f776bf>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

v="${0##*-}"
exec /usr/local/bin/st -n 'st' -c "St-$v" "$@"

# Copyright (C) 2019 by Tom Davis <tom@greyshirt.net>.
