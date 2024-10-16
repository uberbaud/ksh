#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2017-10-15:tw/21.49.54z/9b7653>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}
ED=${VISUAL:-${EDITOR:?Neither VISUAL nor EDITOR is set}}
set -A vopts --


# Usage {{{1
typeset -- this_pgm=${0##*/}
desparkle "$this_pgm"
PGM=$REPLY
function usage {
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-f^t^] ^Ufile^u ^[^Ucheckin_message^u^]
	         Edit a copy of a file in ^B~/hold^b, then overwrite the original
	         with the copy. (More secure than ^Tdoas vim ^Ufile^u^t).
	         ^T-f^t    Force an edit, even if ^Isystem^i and ^Iarchive^i
	               files differ.
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
		f)	warnOrDie=warn;											;;
		h)	usage;													;;
		\?)	die "Invalid option: [1m-$OPTARG[22m.";				;;
		\:)	die "Option [1m-$OPTARG[22m requires an argument.";	;;
		*)	bad_programmer "$Option";								;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
function remove-lockfile { # {{{1
	local lockfile base file expectedCmd
	lockfile=$1/$2
	base=$1
	file=$2
	expectedCmd=/home/tw/bin/ksh/suv
	set -- $(ps -ocommand= -p $(<$lockfile))
	[[ -n ${1:-} && $1 == /bin/ksh			&&
	   -n ${2:-} && $2 == $expectedCmd		&&
	   -n ${3:-} && $3 == $filename
	]]&& return 1
	rm "$lockfile"
} # }}}1
function mv-old-rcs-vs { #{{{1
	NOT-IMPLEMENTED -die
	remove-old-RCS
} # }}}1
function softlink-or-die { # {{{1
	local dRCS dLN
	ln -s "$1" "$2" && return
	sparkle-path "$1";		dRCS=$REPLY
	sparkle-path "$2";		dLN=$REPLY
	die "Could not ^Tln -s^t" "$dRCS" "$dLN"
} # }}}1
function mk-linked-rcs { # {{{1
	local common_rcs_subpath link_to REPLY
	common_rcs_subpath=$RCS_BASE/${1#/}
	link_to=$2/RCS

	needs-path -create -or-die "$common_rcs_subpath"

	if [[ -h $link_to ]]; then
		local RCS dLN dRCS dCMN
		RCS=$(readlink $link_to)
		[[ $RCS == $common_rcs_subpath ]]|| {
			sparkle-path "$link_to";			dLN=$REPLY
			sparkle-path "$RCS";				dRCS=$REPLY
			sparkle-path "$common_rcs_subpath";	dCMN=$REPLY
			die "$dLN ^Bexists^b but" "points to $dRCS" "instead of $dCMN"
		  }
	elif [[ -d $link_to ]]; then
		mv-old-rcs-vs "$link_to" "$common_rcs_subpath"
		softlink-or-die "$common_rcs_subpath" "$link_to"
	elif [[ -e $link_to ]]; then
		sparkle-path "$link_to"
		die "File System Object $REPLY exists" "but is not a directory or link"
	else
		softlink-or-die "$common_rcs_subpath" "$link_to"
	fi
} # }}}1
function main { # {{{1
	holdbase=$HOLD_PATH/$(uname -r)/sys-files
	workingpath=$holdbase/${filepath#/}
	needs-path -create -or-die "$workingpath"

	[[ -d $workingpath/RCS ]]||
		mk-linked-rcs "$filepath" "$workingpath"

	needs-cd "$workingpath"

	workfile=${filename##*/}
	rcsFile=RCS/$workfile,v
	[[ -a $workfile ]]&& {
		[[ -f $workfile ]]||
			die "working file (^B$workfile^b) exits in"	\
				"^B$workingpath^b"							\
				"but is not a file."
	  }

	[[ -f $workfile ]]&& {
		[[ -f $rcsFile ]]||
			ci -q -u -i -t"-Existing hold/sys-file" ./"$workfile"
		co -q -l ./"$workfile" || die "^Tco^t error."
	}
	PREF=''
	if [[ -f $filename ]]; then
		fowner=$(stat -f'%Su' "$filename")
		fgroup=$(stat -f'%Sg' "$filename")
		fperm=$(stat -f'%#Lp' "$filename")
		touch ./"$workfile"
		[[ -r $filename ]]|| PREF=as-root
		if [[ -s $filename ]]; then
			$PREF cat $filename >$workfile
		else
			echo >$workfile
		fi
		CRYPTHASH=$($CKSUM ./"$workfile")
		[[ -f $rcsFile ]]&& {
			set -A errMsg "System file and archived file have diverged."
			[[ $warnOrDie == die ]]&&
				errMsg[1]="Do an RCS ^Tci^t and rerun, or"
			rcsdiff -q -kk ./"$workfile" || warnOrDie "${errMsg[@]}"
			unset errMsg
		  }
	else
		CRYPTHASH=''
		fowner=root
		fgroup=wheel
		fperm=0644
		echo >$workfile
	fi

	[[ -f $rcsFile ]]|| {
		# check in an existing copy so we don't lose that
		ci -q -u -i -t"-$CI_INITIAL_DESCRIPTION" ./"$workfile"
		# but then check it out so we can actually edit it
		co -l ./"$workfile"
	  }

	$ED ./"$workfile"
	trackfile ./"$workfile" # track the copy in case weirdness ensues below
	if [[ -f $rcsFile ]]; then
		# previously checked in
		rcsdiff -kk -q ./"$workfile" ||
			ci -q -u -j ${1:+-m"$*"} ./"$workfile"
	else
		ci -q -u -i -t"-${*:-$CI_INITIAL_DESCRIPTION}" ./"$workfile"
	fi
	[[ -n $CRYPTHASH ]]&& {
		[[ $CRYPTHASH == $($CKSUM ./"$workfile") ]]&& {
			notify 'There were no changes made.' 'Exiting.'
			exit 0
		  }
		[[ $CRYPTHASH != $($PREF $CKSUM "$filename") ]]&& {
			warn "^B$filenameD^b has changed since reading."
			desparkle "$workingpath/$workfile"
			yes-or-no Continue ||
				die "You must manually copy"	\
					"  ^B$REPLY^b"				\
					"to"						\
					"  ^B$filenameD^b"
		  }
	  }
	print -r -- "$filename" >>$LOGFILE
	if [[ -w $filename ]]; then
		cat ./"$workfile" >"$filename"
	else
		set -- -p -F -o "$fowner" -g "$fgroup" -m $fperm -S
		as-root install "$@" ./"$workfile" "$filename"
	fi
} # }}}1

(($#))|| die 'Missing required argument ^Ufile^u.'


needs as-root ci co desparkle fast-crypt-hash get-exclusive-lock $ED	\
	needs-cd needs-path release-exclusive-lock warnOrDie

CKSUM=fast-crypt-hash
CI_INITIAL_DESCRIPTION='OpenBSD system file'
LOCKBASE=${XDG_CACHE_HOME:?}/suv/locks
needs-path -create -or-die "$LOCKBASE"
needs-path -create -or-die $HOME/log
LOGFILE=$HOME/log/logfile

filename=$1; shift
desparkle "$filename"
filenameD=$REPLY
file_or_error=$(realpath "$filename" 2>&1)
[[ $file_or_error == 'realpath: '*': Permission denied' ]]&& {
	: here is where we do **doas $K/suvX.ksh**
  }
[[ $file_or_error == realpath:* ]]&& {
	errmsg=${file_or_error##realpath: *: }
	die "$errmsg: ^B$filenameD^b."
  }
[[ -a $file_or_error ]]&& {
	[[ -f $file_or_error ]]|| die "^B$filenameD^b is not a file."
  }

filename=$file_or_error
filepath=${filename%/*}
[[ $filepath == $HOME?(/*) ]] &&
	die "^T$PGM^t only works outside of ^S\$HOME^s." \
		"Instead, use ^T:W^t inside ^Tvim^t (^Tv^t or ^Tnew^t)."
notify "filepath: $filepath"

# GET AN EXCLUSIVE LOCK ON THE FILE
gsub '/' '%' "$filename"
lockfile=$REPLY
get-exclusive-lock -no-wait "$lockfile" "$LOCKBASE"	|| {
	remove-lockfile "$LOCKBASE" "$lockfile" &&
		get-exclusive-lock -no-wait "$lockfile" "$LOCKBASE"
	} || die "PID $(<$LOCKBASE/$lockfile) has locked ^U$filenameD^u."

print $$>"$LOCKBASE/$lockfile"
# WE HAVE A LOCK

HOLD_PATH=$HOME/hold
RCS_BASE=$HOLD_PATH/common-rcs
needs-path -create -or-die "$RCS_BASE"


(main "$@"); release-exclusive-lock "$lockfile" "$LOCKBASE"; exit

# Copyright (C) 2017 by Tom Davis <tom@greyshirt.net>.
