#!/bin/ksh
# <@(#)tag:csongor.greyshirt.net,2019-04-09:tw/05.43.00z/52c9f48>
# vim: filetype=ksh tabstop=4 textwidth=72 noexpandtab nowrap

set -o nounset;: ${FPATH:?Run from within KSH}

CFGDIR=${XDG_CONFIG_HOME:?}/mail
DBFILE=$CFGDIR/mailcfg.db3
FETCHMAIL_APP_ID=0
FETCHMAIL_ID_FILE=$CFGDIR/fetchids
FETCHMAIL_RC_DIR=$CFGDIR/fetchmail
FETCHMAIL_SKIP_DIR=$FETCHMAIL_RC_DIR/SKIP
FETCHMAIL_MDA_CMD='/usr/local/mmh/bin/rcvstore +inbox'
S_INCLUDE=0
S_IGNORE=1

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
function line-info { # {{{1
	print -- "${1:-}^Nfile:^n $CFILE^N, line:^n ^B$LineNo^b"
} # }}}1
function syntax-err { # {{{1
	local IFS msg ln pad
	pad='      '
	desparkle "$LN"; ln=$REPLY
	{
		print -- "  ^WSyntax error^w: $1"; shift
		line-info "$pad"
		print -- "$pad^N>^n ^F{2}$ln^f"
		(($#))&& for extra; do  print -r -- "$pad^W$extra^w"; done
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
	local prev_autodie SQL_AUTODIE
	SQL_AUTODIE=true
	SQL <<-==SQLite==
		ATTACH '${1:?}' AS mailcfg;
		CREATE TABLE mailcfg.providers (
		    id      INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
		    name    TEXT NOT NULL UNIQUE
		);
		CREATE TABLE mailcfg.services (
		    provider    INTEGER NOT NULL REFERENCES providers (id),
		    protocol    TEXT NOT NULL,
		    host        TEXT NOT NULL,
		    port        INTEGER NOT NULL,
		    PRIMARY KEY (provider,protocol,host)
		);
		CREATE TABLE mailcfg.states (
		    id          INTEGER NOT NULL PRIMARY KEY,
		    label       TEXT NOT NULL UNIQUE,
		    note        TEXT
		);
		INSERT INTO mailcfg.states (id,label,note)
		    VALUES
		        ( $S_INCLUDE, 'get', 'automatially download mail'  ),
		        ( $S_IGNORE, 'skip', 'only download mail manually' )
		        ;
		CREATE TABLE mailcfg.apps (
		    id      INTEGER NOT NULL PRIMARY KEY,
		    name    text NOT NULL UNIQUE
		);
		INSERT INTO mailcfg.apps (id,name)
		    VALUES
		        ($FETCHMAIL_APP_ID,'fetchmail')
		        ;
		CREATE TABLE mailcfg.options (
		    id      INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
		    app     INTEGER NOT NULL REFERENCES apps (id),
		    vals    text NOT NULL,
		    UNIQUE (app,vals)
		);
		CREATE TABLE mailcfg.accounts (
		    id          INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
		    provider    TEXT NOT NULL REFERENCES providers (id),
		    username    TEXT NOT NULL,
		    password    TEXT NOT NULL,
		    state       INTEGER NOT NULL REFERENCES states (id),
		    UNIQUE (provider,username)
		);
		CREATE TABLE mailcfg.acctopts (
		    options     INTEGER NOT NULL REFERENCES options (id),
		    accounts    INTEGER NOT NULL REFERENCES accounts (id),
		    PRIMARY KEY (options,accounts)
		);
		CREATE VIEW mailcfg."account-options" AS
		    SELECT a.id   AS acct,
		           o.app  AS appid,
		           p.name AS app,
		           o.vals AS options
		      FROM acctopts j,
		           accounts a,
		           options  o,
		           apps     p
		     WHERE a.id = j.accounts
		       AND o.id = j.options
		       AND o.app = p.id
		         ;
		CREATE VIEW mailcfg."service-provider" AS
		    SELECT p.name, s.protocol, host, port
		      FROM protocols p, services s
		     WHERE s.protocol = p.id
		         ;
		CREATE VIEW mailcfg."account-services" AS
		    SELECT a.id       AS id,
		           p.name     AS provider,
		           a.username AS username,
		           a.password AS password,
		           t.label    AS state,
		           v.protocol AS protocol,
		           v.host     AS host,
		           v.port     AS port
		      FROM accounts a,
		           providers p,
		           states t,
		           services v
		     WHERE a.provider = p.id
		       AND t.id = a.state
		       AND v.provider = p.id
		         ;
	==SQLite==
} # }}}1
# illegal host name error messages {{{1
baddash_msg='Domain labels may not begin or end with a dash.'
toolonglbl_msg='Domain label exceeds 63 bytes.'
toolongname_msg='Domain name exceeds 253 bytes.'
badchars_msg='Domain labels may only contain ASCII alphanumeric and dashes.'
emptylabel_msg='Domain contains two (2) dots in a row (empty label).'
# }}}1
function is-host-valid { # {{{1
	local IFS REPLY domain i
	local emptylabel badchars baddash toolonglbl toolongname
	IFS=.
	domain=${1:?}
	baddash=false
	toolonglbl=false
	toolongname=false
	badchars=false
	emptylabel=false
	i=0
	set -A e --

	[[ -n $domain ]]|| { syntax-err 'Missing required domain name'; return 1; }
	((${#domain} > 253))&& toolongname=true
	for label in $1; do
		[[ -n $label ]]||						emptylabel=true
		[[ $label == -* || $label == *- ]]&&	baddash=true
		((${#label} > 63))&&					toolonglbl=true
		[[ $label == +([a-z0-9-]) ]]||			badchars=true
	done
	$baddash	 	&& e[i++]=$baddash_msg
	$toolonglbl		&& e[i++]=$toolonglbl_msg
	$toolongname	&& e[i++]=$toolongname_msg
	$badchars		&& e[i++]=$badchars_msg
	$emptylabel		&& e[i++]=$emptylabel_msg

	((${e[*]:+1}))&& syntax-err 'Bad domain name' "${e[@]}"

} # }}}1
function dbify-protocols { # {{{1
	local provider protocol host port prev_verb

	while IFS=$NL read -r LN; do
		((LineNo++))
		case "${LN:-#}" in
			\#*)		:;								;;
			+([a-z]))
				provider=$LN
				SQLify provider
				SQL "INSERT INTO providers (name) VALUES ($provider);"
				;;
			$TAB*)
				[[ -z $provider || $provider == NULL ]]&&
					syntax-err 'No ^Bhost^b for service protocol.'
				set -- $LN
				(($#<3))&& syntax-err 'Missing required service parameter.'
				(($#>3))&& syntax-err 'Too many service parameters.'
				[[ $1 == @(smtps|imap) ]]|| syntax-err 'Unknown protocol'
				is-host-valid "$2"
				[[ $3 == [1-9]+([0-9]) ]]|| syntax-err 'Bad port number.'
				synerred || {
					protocol=$1; host=$2; port=$3
					SQLify protocol host port
					SQL <<-==SQLite==
						INSERT INTO mailcfg.services
								(provider,protocol,host,port)
							SELECT id, $protocol, $host, $port
						  	FROM providers
						 	WHERE name = $provider
						     	;
					==SQLite==
					}
				;;
			*)
				syntax-err 'Invalid directive.'
				;;
		esac
	done
} # }}}1
function sql-want-one { # {{{1
	local c field table otherwise
	field=${1:-Missing parameter _field_}
	table=${2:-Missing parameter _table}
	otherwise=${3:-Missing parameter _otherwise_}

	((${sqlreply[*]:+1}))|| {
		sqlreply[0]=$otherwise
		warn "No ^T$field^t returned from ^T$table^t!"
		return
	  }

	c=${#sqlreply[*]}
	((c==1))|| warn	\
		"Too many ^T${field}^ts returned from ^T$table^t: ^B$c^b"	\
		"${sqlreply[@]}"

} # }}}1
function dbify-accounts { # {{{1
	local provider usr pwd fopts c l state
	integer fopt_id=-1 prv_id=-1 acct_id=-1
	while IFS=$NL read LN; do
		case ${LN:-;} in
			\;*) :;	;;
			@*)
				provider=${LN##@*([ $TAB])}
				SQLify provider
				SQL "SELECT id FROM providers WHERE name = $provider"
				sql-want-one id providers -1
				prv_id=$sqlreply
				;;
			fetchmail=\"*\")
				fopts=${LN#fetchmail=\"}; fopts=${fopts%\"}
				SQLify fopts
				SQL <<-===SQLite===
					INSERT OR IGNORE INTO mailcfg.options (app,vals)
						VALUES ($FETCHMAIL_APP_ID,$fopts)
						;
					SELECT id
					  FROM mailcfg.options
					 WHERE app = $FETCHMAIL_APP_ID
					   AND vals = $fopts
					     ;
				===SQLite===
				sql-want-one "id" "options" -1
				fopt_id=$sqlreply
				;;
			[-+]*)
				[[ $LN == +* ]] && state=$S_INCLUDE || state=$S_IGNORE
				l=${LN##[-+]*([ $TAB])}
				usr=${l%%+([ $TAB])*}
				pwd=${l##"$usr"+([ $TAB])}
				SQLify usr pwd
				SQL <<-===SQLite===
					INSERT OR FAIL INTO mailcfg.accounts
						(provider,username,password,state)
						VALUES ($prv_id, $usr, $pwd, $state)
						;
				===SQLite===
				SQL <<-===SQLite===
					SELECT id
					  FROM mailcfg.accounts
					 WHERE provider = $prv_id
					   AND username = $usr
					     ;
				===SQLite===
				sql-want-one "id" "accounts" -1
				acct_id=$sqlreply
				(( (fopt_id==-1) || (acct_id==-1) ))|| {
					SQL <<-===SQLite===
						INSERT INTO mailcfg.acctopts (options,accounts)
							VALUES ($fopt_id,$acct_id)
							;
					===SQLite===
				  }
				;;
			*)
				syntax-err 'Bad prefix char, unknown line type'
				;;
		esac
	done
} # }}}1
function dbify { # {{{1
	local CFILE LineNo
	CFILE=$CFGDIR/protocols
	LineNo=0

	: ${1:?'Missing parameter dbifiy_???_'}
	dbify-$1 <${2:?Missing parameter _$1_output_file_}
} # }}}1
function create-db { # {{{1
	needs-file -or-die $CFGDIR/protocols
	needs-file -or-die $CFGDIR/accounts
	[[ -f $DBFILE ]]&& rm -f -- "$DBFILE"
	init-db "$DBFILE"
	dbify protocols	"$CFGDIR/protocols"
	dbify accounts	"$CFGDIR/accounts"
} # }}}1
function dump-data { #{{{1
	notify 'DATABASE DUMP'
	SQL '.schema'
	SQL 'SELECT * FROM domains;'
} # }}}1
function timestamp { date +'%Y-%m-%d %H:%M:%S %z'; }
function write-fetch-rc { # {{{1
	local usr pwd host port fopts o
	usr=$1; pwd=$2; host=$3; port=$4; fopts=$5
	cat <<-===
		# ===============================================================
		#   FETCH configuration file generated by $this_pgm
		#      on $(timestamp)
		# ===============================================================
		#   Edit $KDOTDIR/$HOST/sys/$this_pgm to change this file
		# ===============================================================

		set idfile "$FETCHMAIL_ID_FILE"
		set postmaster "$(id -un)"
		set softbounce

		poll $host protocol imap
		     port     $port
		     username '$usr'
		     password '$pwd'
		$(for o in $fopts; do print "     $o"; done)
		     mda      "$FETCHMAIL_MDA_CMD"
		===

} # }}}1
function create-one-fetchmail-file { # {{{1
	local id usr pwd state host port sqlfields fopts outpath
	id=${1:?Missing parameter _username_}
	SQL <<-===SQLite===
		SELECT username, password, state, host, port
		  FROM "account-services"
		 WHERE protocol = 'imap'
		   AND id = $id
	===SQLite===
	# save the results so we can use sqlreply in a called function
	sql-want-one row account-services '-0-'
	splitstr "${SQLSEP:?}" "$sqlreply" sqlfields
	set -- "${sqlfields[@]}"
	(($# == 5))|| {
		warn "Missing bits in ^Taccount-services^t for ^Vid^v ^O=^o ^T$id^t."
		return
	  }
	usr=$1; pwd=$2; state=$3; host=$4; port=$5


	SQL <<-===SQLite===
		SELECT options
		  FROM "account-options"
		 WHERE acct  = $id
		   AND appid = $FETCHMAIL_APP_ID
	===SQLite===
	fopts=
	((${sqlreply[*]:+1}))&& {
		c=${#sqlreply[*]}
		((c==1))|| warn "Too many ^Toptions^t returned for ^Vid^v^O=^o^T$id^T"
		fopts=$sqlreply
	  }
	case $state in
		get)	outpath=$FETCHMAIL_RC_DIR;							;;
		skip)	outpath=$FETCHMAIL_SKIP_DIR;						;;
		*)		warn "Unknown mail download state: ^T$state^t.";	;;
	esac

	write-fetch-rc "$usr" "$pwd" "$host" "$port" "${fopts:-}" >$outpath/"$usr"
	chmod 0600 $outpath/"$usr"

} # }}}1
function create-fetchmail-files { # {{{1
	local uid

	# clean
	rm -f $FETCHMAIL_RC_DIR/* $FETCHMAIL_SKIP_DIR/* >/dev/null 2>&1

	# do the new ones
	SQL 'SELECT id FROM mailcfg.accounts'
	((${sqlreply[*]:+1}))|| { warn "No users found!"; return; }
	set -- "${sqlreply[@]}"
	for uid { create-one-fetchmail-file "$uid"; }
} # }}}1
function create-smtpd-files { # {{{1
	NOT-IMPLEMENTED
} # }}}1
function main { # {{{1
	create-db
	$DEBUG && dump-data
	((Errors))&& {
		s=s
		((Errors==1))&& s=
		die "^B$Errors^b error$s. Will not continue."
	  }
	create-fetchmail-files
	create-smtpd-files
	timestamp >$CFGDIR/.LAST_UPDATED
} # }}}1

needs SQL SQLify needs-file sql-fields
SQL_AUTODIE=warn

SynErred=false
Errors=0
LineNo=0
TAB='	'
NL='
' #^ <- new line captured here

main "$@"; exit

# Copyright (C) 2019 by Tom Davis <tom@greyshirt.net>.
