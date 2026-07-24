#!/bin/ksh
# <@(#)tag:tw.lukas.uberbaud.foo,2026-03-09,21.11.29z/5ac73f1>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: "${FPATH:?Run from within KSH}"

function with-var-name { # {{{1
	local VNAME
	VNAME=${1:?}
	set -A $VNAME --
	I=0
	eval "function + { local v; for v { $VNAME[I++]=\${USE_PREFIX:-}\$v; }; }"
} #}}}1


needs clang-tidy

USE_PREFIX=-Wno-
with-var-name NOWARN
  + pre-c23-compat
  + pre-c11-compat

USE_PREFIX=-I
with-var-name INCLUDES
  + ${HOME:?}/local/share/c/api

USE_PREFIX=
with-var-name FLAGS
  + -Wall
  + -std=c23
  + -fcolor-diagnostics
  + -fdiagnostics-show-option

cflags="${FLAGS[*]} ${NOWARN[*]} ${INCLUDES[*]}"

exec clang-tidy "$@" -- $cflags

# Copyright (C) 2026 by Tom Davis <tom@greyshirt.net>.
