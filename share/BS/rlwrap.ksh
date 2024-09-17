#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2023-09-05,14.51.21z/3f28e41>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker
# =========================================================================
#  Wrap rlwrap with a prefix notice
# =========================================================================

set -o nounset
RLWRAP=/usr/local/bin/rlwrap
needs $RLWRAP
CMD=
if [[ $* == *' -- '* ]]; then
	last=false
	for o; do
		$last && { CMD=$o; break; }
		[[ $o == -- ]]|| continue
		last=true
	done
else
	# kludge
	for CMD; do [[ $CMD == -* ]]|| break; done
fi
[[ -z ${CMD:-} || $CMD == -* ]]&& exec $RLWRAP "$@"

if [[ -t 2 ]]; then
	E=$(print \\033)
	B="$E[1;39m"; F="$E[31m"; G="$E[0;38;5;248m"; W="$E[38;5;172m"; N="$E[0;39m"
else
	E=; B=; F=; G=; W=; N=
fi

print -ru2 -- \
	"$W== Notice$G: Wrapping $B$CMD$G with ${B}rlwrap$G. $W==$N"

[[ -x $RLWRAP ]]&& exec $RLWRAP "$@"

print -ru2 -- "  ${F}Failed${N}: No executable ${B}$RLWRAP${N}."
false


# Copyright (C) 2023 by Tom Davis <tom@greyshirt.net>.
