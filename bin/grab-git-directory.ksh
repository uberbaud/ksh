#!/bin/ksh
# @(#)[:S8QtKB8x1b<<y}!`R(MJ: 2017-11-19 19:08:18 Z tw@csongor]
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^Uurl^u
	         Scrape a git web page to git the current files for a repository sub-directory.
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
function bad_programmer {	# {{{2
	die 'Programmer error:'	\
		"  No getopts action defined for [1m-$1[22m."
  };	# }}}2
while getopts ':h' Option; do
	case $Option in
		h)	usage;													;;
		\?)	die "Invalid option: [1m-$OPTARG[22m.";				;;
		\:)	die "Option [1m-$OPTARG[22m requires an argument.";	;;
		*)	bad_programmer "$Option";								;;
	esac
done
# remove already processed arguments
shift $(($OPTIND - 1))
# ready to process non '-' prefixed arguments
# /options }}}1
function warnOrDie { #{{{1
	case $warnOrDie in
		die)  die "$@";												;;
		warn) warn "$@";											;;
		*)    die '[1mProgrammer error[22m:' \
					'warnOrDie is [1m${warnOrDie}[22m.';		;;
	esac
} # }}}1

(($#))||	die 'Missing required ^Uurl^u for github directory page.'
(($#>1))&&	die 'Too many arguments. Expected one (1).'

giturl=https://github.com
gitraw=https://raw.githubusercontent.com
[[ $1 == $giturl/* ]]|| die 'URL does not point to ^Bgithub^b.'

# $AWKPGM {{{1
AWKPGM="$(cat)" <<-\
	\==AWKPGM==
    /^[ \t]*<td class="content">/ {
			p=1
			next
		}
	p == 1 && /<a href=/ {
			p=0
			sub(/^.*href="/,"")		# remove before the URL
			sub(/".*$/,"")			# remove after the URL
			sub(/\/blob\//,"/")		# remove bit not in the *raw* URL
			print
		}
	/^ +<\/tbody>/ {
			exit 0
		}
	==AWKPGM==
# }}}1
errs=0
warnOrDie=die
function grab { # {{{1
	notify "Getting ^B$1^b."
	if curl -#Lo "$1" "$2"; then
		print -n '\033[A\r\033[2K' # clear progress bar and overwrite
	else
		warnOrDie "Could not ^Tcurl^t ^B$1^b."
		((errs++))
		return 1
	fi
} # }}}1

function main {
	local prjdir="${1##*/}" filelist f fname
	mkdir "$prjdir" ||
		die "Could not ^Tmkdir^t ^B$prjdir^b."
	grab "$prjdir.html" "$1"
    splitstr NL "$(awk "$AWKPGM" $prjdir.html)" filelist

	errs=0
	warnOrDie=warn
	for f in "${filelist[@]}"; do
		grab $prjdir/"${f##*/}" "$gitraw$f"
	done

	((errs))&&
		die "Problem downloading ^B$errs^b of ^B${#filelist[*]}^b files."

	return 0
}

main "$@"; exit

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
