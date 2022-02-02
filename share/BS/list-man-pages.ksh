#!/bin/ksh

xtra=
this_pgm=${0##*/}
function usage {
	print -u2 "$this_pgm [-r]"
	print -u2 "    List all man pages in /etc/man.conf directories."
	print -u2 "    -r  restrict pages to *.[1-9]"
	exit 0
}

case ${1:-} in
	-r) xtra='-name *.[1-9]'; shift;	;;
	-h) usage;							;;
esac
(($#))&& {
	print -u2 "Error: ${0##*/}: unknown options $*"
	exit 64 # USAGE
  }

find $(awk '/^manpath/ {print $2}' /etc/man.conf) \! -name \*.db $xtra -type f |
	sed -E -e 's:^/.+/::' -e 's:\.[^.]$::' |
	sort | uniq
