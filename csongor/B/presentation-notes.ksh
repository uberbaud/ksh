#!/bin/ksh

needs cd h1 less sed sparkle
cd notes || die 'Could not ^Tcd^t to ^Snotes^s.'

for f in *; do
	f=${f%.txt}
	h1 "Page ${f##*(0)}"
	sed -e 's/^;/ /' $f.txt|sparkle
done | less
