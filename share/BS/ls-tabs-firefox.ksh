#!/bin/ksh
# <@(#)tag:tw@lukas.uberbaud.foo,2026-06-25:13.02.36z/5a4836b>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

doas -u firefox ~firefox/bin/ls-tabs.ksh "$@"; exit

# Copyright (C) 2026 by Tom Davis <tom@greyshirt.net>.
