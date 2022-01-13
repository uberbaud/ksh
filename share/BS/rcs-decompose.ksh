#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2021-11-25,02.04.21z/328488b>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

exec 3>>~/log/RCS-rlog-exceptions
SEP=$(print '\035')
function process-version-info { # {{{1
	local D R Z
	while IFS=' ' read key ln; do
		case $key in
			revision)
				R=$ln
				;;
			date:)
				D=$(print -r -- "${ln%%;*}"|tr -cd '[0-9]')
				break # put everything after in the message file
				;;
			*)
				# Probably nothing will match
				print -ru3 -- "$vORIGIN: $key $ln"
				;;
		esac
	done
	[[ -n ${D-} ]]|| return
	N=$D-$1
	cat >$N.msg
	F=${2%",v"}
	print -u2 -- "        $R"
	co -q -r$R "$F"
	mv "$F" "$N".text
} # }}}1
function rcs-decompose { # {{{1
	local vID V f file1 sLen sName
	vID=$1
	vORIGIN=$2
	V=${2##*/}

	print -u2 -- " >>> $vORIGIN"

	ln -sf "$2" "$V"
	needs-path -or-die $vID

	# file1 depends on split options: -a# and name (last parameter), so
	# let's compute it
	sName=$vID/
	sLen=3

	i=$sLen; file1=$sName; while ((i--)) { file1=${file1}a; }

	rlog -E"$SEP" -S"$SEP" "$V" | split -a$sLen -p"^$SEP\$" - "$sName" ||
		die 'Problem with ^Trlog^t^O|^o^Tsplit^t'

	# special handling of first file, which is the header
	sed -E '1,/^description:$/d' "$file1" >DESCRIPTION.$vID

	# process all the files that aren't the header ($file1)
	rm "$file1"
	dir-is-empty $vID && return
	for f in $vID/*; do
		sed -E '1d' "$f" | process-version-info $vID "$V"
	done

} # }}}1

#--------8<------------------------8<--------
# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^Urcs-repo,v^u ^Uid^u
	         Save the description, all the versions and log messages from an RCS repository file (*,v).
	           ^Urcs-repo,v^u  the name of an RCS repository file
	           ^Uid^u          an integer unique id for this repo,v
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
while getopts ':h' Option; do
	case $Option in
		h)	usage;															;;
		\?)	die USAGE "Invalid option: ^B-$OPTARG^b.";							;;
		\:)	die USAGE "Option ^B-$OPTARG^b requires an argument.";				;;
		*)	bad-programmer "No getopts action defined for ^T-$Option^t."	;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
(($#<1))&& die 'Missing required parameter ^Urcs-repo,v^u.'
(($#>2))&& die 'Too many parameters. Expected two (2).'

needs dir-is-empty needs-file rlog split

needs-file -or-die "$1"
rcs-decompose "${2:?}" "$1"; exit

# Copyright (C) 2021 by Tom Davis <tom@greyshirt.net>.
