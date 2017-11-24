#!/bin/ksh
# vim: ft=ksh

: ${FPATH:?No FPATH, are you running in ksh}

BKSP=''

echo 'creating'
man ksh |
	sed -E									\
		-e 's/\^/^^/'						\
		-e 's/(_'$BKSP'.)+/^U&^u/g'			\
		-e 's/(.'$BKSP'.)+/^B&^b/g'			\
		-e 's/.'$BKSP'//g'					|
	sed -ne '/^     \^Balias\^b /,/^             non-zero\.$/p' |
	sed -e 's/^     //' |
	split -p '^[^[:space:]]'

echo 'renaming'
for x in x*; do
	read -r name therest <$x
	name="${name##+(^[BU])}"
	name="${name%%+(^[bu])}"
	[[ $name == '[' ]]&& name=test
	if [[ -f $name ]]; then
		printf '  concat %s to %s.\n' $x $name
		cat $x >> "$name"
		rm $x
	else
		printf '  renaming %s to %s.\n' $x $name
		mv $x "$name"
	fi
done
