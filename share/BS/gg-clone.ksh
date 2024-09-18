#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2023-12-27,22.40.47z/5861ee1>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

TRAPSIGS='EXIT HUP INT QUIT TRAP BUS TERM'

# Usage {{{1
typeset -- this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-f^t^] ^Uremote^u ^[^Urepo dir^u^]
	         ^Tgit clone^ts a bare repository into
	             ^SREPOS_HOME^s/^Uhost/and/path/repo.git^u
	         ^Tgot checkout^ts that repository into ^Urepo dir^u or a directory
	             name based on the remote repo name.
	         ^GNote:^g ^T$PGM^t ^Goutputs the repository and worktree paths as^g
	                  ^Gthe variables^g ^SWORKTREE_PATH^s ^Gand^g ^SREPOSITORY_PATH^s
	                  ^Gin a form that can be^g ^Teval^t^Ged by the shell.^g

	         ^T-f^t  Force using ^Uremote^u even if it doesn't ^Ilook^i like a
	             remote repository name.
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
warnOrDie=die
while getopts ':fh' Option; do
	case $Option in
		f)	warnOrDie=warn;										;;
		h)	usage;												;;
		\?)	die "Invalid option: ^B-$OPTARG^b.";				;;
		\:)	die "Option ^B-$OPTARG^b requires an argument.";	;;
		*)	bad_programmer "$Option";							;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
function show_var { #{{{1
	local vname=$1 val
	eval val=\$$vname
	shquote "$val"
	print -r -- "$vname='$REPLY'"
} # }}}1
function clean-up { # {{{1
	local i dword
	remove_on_die-is-empty && return

	if [[ ${#remove_on_die[*]} -eq 1 ]]; then
		dword=directory
	else
		dword=directories
	fi

	warn 'Use'
	i=${#remove_on_die[*]}
	while ((i--)); do
		print -- "                 ^T${remove_on_die[i]}^T"
	done | sparkle >&2
	print -u2 -- "          to remove the added but unused $dword."
} # }}}1
function do-git-clone-or-update { # {{{1
	local remote baredir
	remote=${1:?}
	baredir=${2:?}
	if [[ -d $baredir ]]; then
		command git -C "$baredir" rev-parse 2>/dev/null || {
			sparkle-path "$baredir"
			die "$REPLY exists but is not a ^Tgit^t repository."
		  }
		notify 'git fetch'
		command git -C "$baredir" fetch --all ||
			die 'Could not update (fetch --all).'
	else
		notify 'git clone'
		command git clone --bare "$remote" "$baredir" >&2 ||
			"Could not clone."
	fi
} # }}}1
function main { # {{{1
	local R repo repo_base newdir
	repo=$1
	newdir=$2

	# git worktree directory
	WORKTREE_PATH=$PWD/$newdir
	[[ -d $WORKTREE_PATH ]]|| {
		needs-path -create -or-die "$WORKTREE_PATH"
		shquote "$WORKTREE_PATH"
		+remove_on_die "rmdir $REPLY"
	  }

	# git bare repository directory
	R=${repo##@(file|git|http|https|ssh):*(/)}	# handle std schema names
	R=${R#*@}; R=${R%:*}						# handle ssh protocol name
	REPOSITORY_PATH=$REPOS_HOME/$R
	repo_base=${REPOSITORY_PATH%/*}
	[[ -d $repo_base ]]|| {
		needs-path -create -or-die "$repo_base"
		shquote "$repo_base"
		+remove_on_die "rmdir $REPLY"
	  }

	needs-cd -or-die "$repo_base"

	R=${R##*/}
	do-git-clone-or-update "$repo" "$R" >&2 ||
		die "^Tgit clone --bare^t ^B$repo^b"
	shquote "$REPOSITORY_PATH"
	+remove_on_die "rm -rf $REPLY"

	needs-cd -or-die "$R"
	command got checkout "$REPOSITORY_PATH" "$WORKTREE_PATH" >&2 || {
		rp='"^O$^o^VREPOSITORY_PATH^v^T"^t'
		wp='^T"^t^O$^o^VWORKTREE_PATH^v^T"^t'
		die "^Tgot checkout $rp $wp" \
			"REPOSITORY_PATH=^S$REPOSITORY_PATH^s" \
			"WORKTREE_PATH=^S$WORKTREE_PATH^s"
		  }

	needs-cd -or-die "$WORKTREE_PATH"
	if [[ -n ${HOST:-} ]]; then
		msg=$(command got branch "$HOST" 2>&1) ||
			warn '^Tgot branch ^O$^o^VHOST^v' "HOST=^S$HOST^s" "$msg"
		msg=$(command got update -b "$HOST" 2>&1) ||
			warn 'got update -b ^O$^o^VHOST^v' "HOST=^S$HOST^s" "$msg"
		: # return true so wrapper functions get a good return
	else
		warn 'Could not create or switch to branch ^O$^o^VHOST^v.' \
			'^VHOST^v is empty or not set.'
	fi

	trap - $TRAPSIGS
	show_var WORKTREE_PATH
	show_var REPOSITORY_PATH

} # }}}1

needs needs-path needs-cd new-array shquote warnOrDie
(($#))|| die 'Missing required parameter ^Uremote^u'
(($#<=2))||
	die 'Too many parameters.' \
		'Expected only ^Uremote^u and optionally ^Urepo dir^u.'

if [[ $1 == @(http|https|ftp|ftps|ssh):* ]]; then	# std schema rep
	repo=$1
elif [[ -d $1 ]]; then								# local file
	repo=file://$(realpath "$1")
	warnOrDie "^Brepo^b is local" "Maybe use ^Tgit clone^t instead?"
													# ssh as scp style
elif [[ $1 == ?(+([!:/@])@)+(+([A-Za-z0-9-]).)+([A-Za-z0-9-]):* ]]; then
	local f t
	t=${1#*:}
	f=${1%":$t"}
	repo=ssh://$f/$t
	warn "Converting ^Brepo^b from ^Bscp^b format to ^Bssh^b schema:"	\
		"$1"	\
		"$repo"
	yes-or-no 'Is the new repo name correct' || die "Try again."
else
	die "Parameter does not appear to be a REPOSITORY_PATH name."
fi

if [[ -n ${2-} ]]; then
	newdir=$2
else
	newdir=${repo##*/}
	newdir=${newdir%.git}
	[[ -n $newdir ]]|| die "Could not form a directory name from ^B$repo^b."
fi

new-array remove_on_die
trap clean-up $TRAPSIGS

main "$repo" "$newdir"; exit

# Copyright (C) 2021,2023 by Tom Davis <tom@greyshirt.net>.
