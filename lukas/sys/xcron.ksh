#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-08-06:tw/17.15.13z/5565e00>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

(($#))&& {
	sparkle <<-==SPARKLE==
		Did not expect arguments.
		Runs ^Talarmwatch.sh^t and ^Tsleep^ts.
	==SPARKLE==
	exit 0
  }

THIS_PGM=xcron
get-exclusive-lock -no-wait "$THIS_PGM" ||
	die "^B$THIS_PGM^b is already running."
trap "release-exclusive-lock '$THIS_PGM'" EXIT

exec >/home/tw/log/xcron 2>&1
exec </dev/null
cd /home/tw/.local/bin || {
	printf 'xcron: could not cd'
	exit 1
}
while :; do
	( /home/tw/.local/bin/alarmwatch.sh )&
	sleep $((60-$(date -u +%s)%60))
done

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
