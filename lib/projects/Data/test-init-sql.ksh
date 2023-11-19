#!/bin/ksh

rm -f x??
split -p '^(CREATE|DROP|INSERT)' projects.sql3
set -- x??
sed -i -e 1d -e '/LOAD/d' -e '/^-- /s///' $1
shift
for s; do
	clear
	h3 $s
	cat xaa $s | \sqlite3 -echo
	h3 '─'
	yes-or-no Next || break
done
rm x??
