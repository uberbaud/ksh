#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2019-04-09:tw/05.43.00z/52c9f48>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
typeset -- this_pgm="${0##*/}"
function usage {
	desparkle "$this_pgm"
	PGM="$REPLY"
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-d^t^]
	         Create fetchmail and smtpd necessary files.
	           ^T-d^t  Debug (dump database)
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
DEBUG=false
while getopts ':dh' Option; do
	case $Option in
		d)	DEBUG=true; SQL_VERBOSE=true;						;;
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
function warnOrDie { #{{{1
	case $warnOrDie in
		die)  die "$@" 'Use [1m-f22m to force an edit.';		;;
		warn) warn "$@";											;;
		*)    die '[1mProgrammer error[22m:' \
					'warnOrDie is [1m${warnOrDie}[22m.';		;;
	esac
} # }}}1

needs SQL
SQL_AUTODIE=warn

cfgdir="$(readlink -fn "${0%/*}/")"

SynErred=false
Errors=0
LineNo=0
TAB='	'
NL='
' #^ <- new line captured here
function line-info { # {{{1
	print -- "${1:-}^Nfile:^n $CFILE^N, line:^n ^B$LineNo^b"
} # }}}1
function syntax-err { # {{{1
	desparkle "$LN"
	{
		print -- "  ^WSyntax error^w: $1"
		line-info '      '
		print -- "      ^K{7}^N$REPLY^n^k"
	} | sparkle >&2
	SynErred=true
	((++Errors))
} # }}}1
function synerred { # {{{1
	local x=$SynErred	# save for later
	SynErred=false		# clear for next time
	$x					# return what SynErred *was*
} # }}}1
function init-db { # {{{1
	local autodie=$SQL_AUTODIE
	SQL_AUTODIE=true
	SQL <<-==SQLite==
		CREATE TABLE aliases (
			alias	TEXT NOT NULL PRIMARY KEY
		);
		CREATE TABLE domains (
			domain	TEXT NOT NULL PRIMARY KEY,
			alias	TEXT NOT NULL REFERENCES aliases
		);
		CREATE TABLE services (
			alias		TEXT NOT NULL REFERENCES aliases,
			protocol	TEXT NOT NULL,
			host		TEXT NOT NULL,
			port		INTEGER NOT NULL,
			PRIMARY KEY (alias,protocol)
		);
		CREATE TABLE secrets (
			domain		TEXT NOT NULL REFERENCES domains,
			username	TEXT NOT NULL,
			password	TEXT NOT NULL
		);
	==SQLite==
	SQL_AUTODIE=$autodie
} # }}}1
function is-domain-valid { # {{{1
	[[ -n $1 ]]|| { 
		syntax-err 'Missing required domain name.'
		return 1
	  }
	[[ $1 == +([A-Za-z0-9-])*(.+([A-Za-z0-9-])) ]]|| {
		syntax-err 'Bad domain name.'
		return 2
	  }
	return 0
} # }}}1
function is-alias-valid { # {{{1
	[[ $1 == +([A-Za-z0-9_-]) ]]&&
		return 0
	syntax-err 'Bad alias name ([A-Za-z0-9_-]+)'
	return 1
} # }}}1
function dbify-secrets { # {{{1
	local IFS="$NL"
	CFILE=$cfgdir/secrets
	LineNo=0
	while read -r LN; do
		((LineNo++))
		[[ ${LN:-\#} == \#* ]]&& continue
		set -- $(IFS="$TAB"; for i in $LN; { print $i; })
		domain="${1:-}"
		username="${2:-}"
		password="${3:-}"
		is-domain-valid "$domain" || continue
		[[ -n $username ]]|| syntax-err 'Missing ^Uusername^u'
		[[ -n $password ]]|| syntax-err 'Missing ^Uusername^u'
		synerred && return 1
		SQLify domain username password
		SQL <<-==SQLite==
			INSERT INTO secrets (domain,username,password)
				VALUES ($domain,$username,$password)
				;
		==SQLite==
		(($?))&& {
			if [[ ${reply[0]} == *'FOREIGN KEY constraint failed' ]]; then
				SQL 'SELECT domain FROM domains;'
				(
					IFS=" $TAB$NL"
					warn "Domain ^S$1^s is not aliased in ^Bprotocols^b." \
						'Valid domains are:'	\
						"  ${reply[*]}"			\
						"$(line-info)"
				)
			else
				warn 'Unknown database error' "${reply[@]}" "$(line-info)"
			fi
		  }
	done <$CFILE
} # }}}1
function dbify-protocols { # {{{1
	local IFS="$NL"
	CFILE=$cfgdir/protocols
	LineNo=0
	while read -r LN; do
		((LineNo++))
		case "${LN:-#}" in
			\#*)	:;			;;
			*=*)
				[[ $LN == *\'* ]]&&
					syntax-err 'Unexpected quote character.'
				domain="${LN%%=*}"
				is-domain-valid "$domain"
				alias="${LN##*=}"
				is-alias-valid "$alias"
				[[ $LN == $domain=$alias ]]||
					syntax-err 'Too many equals characters.'
				synerred || SQL <<-==SQLite==
					INSERT OR IGNORE INTO aliases (alias)
						VALUES ('$alias')
						;
					INSERT INTO domains (domain,alias)
						VALUES ('$domain','$alias');
				==SQLite==
				;;
			+([A-Za-z0-9_-]))
				ALIAS="$LN"
				;;
			$TAB*)
				[[ -n $ALIAS ]]||
					syntax-err 'No ^Balias^b for service protocol.'
				set -- $(IFS="$TAB"; for l in $LN; do print $l; done)
				(($#<3))&& syntax-err 'Missing required service parameter.'
				(($#>3))&& syntax-err 'Too many service parameters.'
				[[ $1 == @(smtps|imaps) ]]|| syntax-err 'Unknown protocol'
				is-domain-valid "$2"
				[[ $3 == [1-9]+([0-9]) ]]|| syntax-err 'Bad port number.'
				synerred || SQL <<-==SQLite==
					INSERT INTO services (alias,protocol,host,port)
						VALUES ('$ALIAS','$1','$2','$3')
						;
				==SQLite==
				;;
			*)
				syntax-err 'Invalid directive.'
				;;
		esac
	done <$CFILE
} # }}}1
function create-db { # {{{1
	[[ -f $cfgdir/protocols ]]|| die 'Cannot find ^Sprotocols^s file.'
	[[ -f $cfgdir/secrets ]]|| die 'Cannot find ^Ssecrets^s file.'
	init-db
	dbify-protocols
	dbify-secrets
} # }}}1
function dump-data { #{{{1
	notify 'DATABASE DUMP'
	SQL '.schema'
	SQL 'SELECT * FROM aliases;'
} # }}}1

# wrap script guts in a function so edits to this script file don't 
# affect running instances of the script.
function main {
	create-db
	$DEBUG && dump-data
	((Errors))&& {
		s=s
		((Errors==1))&& s=
		die "^B$Errors^b error$s. Will not continue."
	  }
	create-fetchmail-files
	create-smtpd-files
}

main "$@"; exit

# Copyright (C) 2019 by Tom Davis <tom@greyshirt.net>.
