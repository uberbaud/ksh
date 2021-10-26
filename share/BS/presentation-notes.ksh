#!/bin/ksh

needs cd h1 less sed sparkle needs-cd
needs-cd -or-die notes

for f in *; do
	f=${f%.txt}
	h1 "Page ${f##*(0)}"
	sed -e 's/^;/ /' $f.txt|sparkle
done | less
