#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2023-06-09,00.30.39z/39d939b>

# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: ${FPATH:?Run from within KSH}

# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm"
	PGM=$REPLY
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^Usearch terms^u
	         Show matching projects and ^Tcd^t to selected project.
	       ^T$PGM inc^t ^Udirectory^u
	         Incorporate an existing project directory using its ^TPROJECT^t file.
	       ^T$PGM ls^t ^[^Usearch terms^u^]
	         List all or matching projects.
	       ^T$PGM new^t
	         Create a new project.
	       ^T$PGM help^t^|^T-h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
# process -options {{{1
while getopts ':h' Option; do
	case $Option in
		h)	usage;															;;
		\?)	die USAGE "Invalid option: ^B-$OPTARG^b.";						;;
		\:)	die USAGE "Option ^B-$OPTARG^b requires an argument.";			;;
		*)	bad-programmer "No getopts action defined for ^T-$Option^t.";	;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
function create-db { # {{{1
	local SQL_VERBOSE
	SQL_VERBOSE=true
	h3 "BEGIN: $PRJDB"
	SQL <<-===SQL===
	CREATE TABLE prj."clients" (
	    -- who requested the project
	    -- see also: "client-project-assoc"
	    "id"    INTEGER NOT NULL PRIMARY KEY,
	    "name"  text NOT NULL UNIQUE ON CONFLICT ABORT
	  );
	INSERT INTO prj."clients" (name)
	  VALUES
	    ('tw')
	  ;
	CREATE TABLE prj."types" (
	    -- available project types
	    "id"     INTEGER NOT NULL PRIMARY KEY,
	    "label"  text NOT NULL UNIQUE ON CONFLICT ABORT,
	    "descr"  text
	  );
	INSERT INTO prj.types (label,descr)
	  VALUES
	    ('facility',   'code or object providing infrastructure'),
	    ('tool',       'product used to create other products'),
	    ('product',    'application for end users'),
	    ('frame',      'Containers such as Web sites, templates, etc.')
	  ;
	CREATE TABLE prj."projects" (
	    -- top-level project relation
	    "id"      INTEGER NOT NULL PRIMARY KEY,
	    "began"   integer NOT NULL UNIQUE DEFAULT (unixepoch('now')),
	    "type"    integer NOT NULL REFERENCES "types" ("id"),
	    "alias"   text NOT NULL UNIQUE, -- compact-timestamp of "began"
	    "summary" text,                 -- name: short description
	    "details" text                  -- long description
	  );
	CREATE TABLE prj."client-project-assoc" (
	    -- connects multiple clients to a project
	    "id"      INTEGER NOT NULL PRIMARY KEY,
	    "client"  integer NOT NULL REFERENCES "clients" ("id"),
	    "project" integer NOT NULL REFERENCES "projects" ("id"),
	    UNIQUE ("client","project") ON CONFLICT ABORT
	  );
	CREATE TABLE prj."staten" (
	    -- available project states
	    "id"      INTEGER NOT NULL PRIMARY KEY,
	    "label"   text NOT NULL ON CONFLICT ABORT
	  );
	INSERT INTO prj."staten" ("label")
	  VALUES
	    ('design'),
	    ('implement'),
	    ('prove'),
	    ('release'),
	    ('update'),
	    ('abandon')
	  ;
	CREATE TABLE prj."status" (
	    -- status of a project at a given time
	    "id"      INTEGER NOT NULL PRIMARY KEY,
	    "project" integer NOT NULL REFERENCES "projects" ("id"),
	    "when"    integer NOT NULL DEFAULT (unixepoch('now')),
	    "status"  integer NOT NULL REFERENCES "staten" ("id"),
	    "note"    text
	  );
	CREATE VIEW prj.gist AS
	    -- "projects" with referenced relations incorporated
	    SELECT p."id", p."began", p."name", p."summary", p."details",
	           group_concat(c."name") AS "client-list",
	           s."when", n."label" AS status, s."note"
	      FROM "projects" p,
	           "clients" c,
	           "client-project-assoc" cpa,
	           "status" s,
	           "staten" n
	     WHERE "project" = p."id"
	       AND c."id" = cpa."client"
	       AND s."project" = p."id"
	       AND n."id" = s."status"
	     GROUP BY p."id"
	    HAVING s."when" = max(s."when")
	         ;
	===SQL===
	h3 "DONE: $PRJDB"
} #}}}1
function parse-project-file { # {{{1
	local extra missing

	# read key:val header
	while IFS="$TAB" read key val; do
		[[ -n $key ]]|| break
		key=${key%:}
		if [[ $key == @(began|clients|type|summary|details) ]]; then
			eval "$key=\$val"
		else
			extra=${extra+=$extra, }^V$key^v
		fi
	done

	# skip any blank lines at the beginning
	while IFS= read ln; do
		[[ -z $ln ]]|| break
	done

	# read long description (details)
	details=$ln
	while IFS= read ln; do
		details=$details$NL$ln
	done

	# verify all required bits are there
	for k in began clients type summary details; do
		eval "[[ -n \${$k:-} ]]" || missing=${missing+=$missing, }^V$k^v
	done

	# show errors if any, exit accordingly
	[[ -z ${extra:-} || -z ${missing:-} ]]||
		warn 'Syntax error in ^TPROJECT^t file:'		\
			${extra:+"Unexpected keys:" "    $extra"}	\
			${missing:+"Missing keys:" "    $missing"}

} # }}}1
function verify-began { # {{{1
	local dfmt
	set -- $began
	[[ $1 == 20[0-9][0-9]-[01][0-9]-[0123][0-9] ]]||
		warn 'Bad date format' || return
	[[ $2 == [0-2][0-9]:[0-5][0-9]:[0-5][0-9] ]]||
		warn 'Bad time format' || return

	[[ $3 == [A-Z][A-Z][A-Z] ]]||
		warn 'Bad timezone format' || return
	unixtm=$(date -j -f '%Y-%m-%d %H:%M:%S %Z' +%s "$began") ||
		warn 'Bad format for ^Tbegan^t' || return
} # }}}1
function verify-alias { # {{{1
	local x
	[[ -n ${unixtm:-} ]]||
		bad-programmer '^Tunixtm^t MUST be set before calling ^Tverify-alias^t.'

	x=$(compact-timestamp $(date -j -r $unixtm +'%Y %m %d %H %M %S'))
	[[ ${alias:?} == ${x#?} ]]||
		warn '^Talias^t and ^Tbegan^t do not match.' || return
} # }}}1
function verify-type { # {{{1
	local t tstr
	SQL 'SELECT label FROM prj.types;'
	for t in "${sqlreply[@]}" ''; do
		[[ $t == $type ]]&& break
	done
	[[ -n $t ]]&& return

	integer i=1 n=${#sqlreply[*]}
	tstr="^T${sqlreply[0]}^t"
	while ((i<n-1)); do
		tstr="$tstr, ^T${sqlreply[i]}^t"
		((i++))
	done
	((i<n))&& tstr="$tstr, or ^T${sqlreply[i]}^t"

	warn "^T$type^t is not in ^Tprj.types^t." \
		"Can be one of $tstr."
} # }}}1
function search-files { # {{{1
	local findstr
	findstr="$1"
	awk -f /dev/stdin $PRJFLDR/*/PROJECT <<-\
		===AWK===
		BEGIN { FS = " +\\\\| +" }
		\$1 == "summary" && \$2 ~ /$findstr/ {
				n = split(FILENAME,y,"/");
				print y[n-1]"|"\$2
				nextfile
			}
		===AWK===
} # }}}1
function search { # {{{1
	local IFS D
	IFS=$NL
	set -- $(search-files "$*")
	case $# in
		0)	warn "no match"; return;	;;
		1)	D=${1%%\|*};				;;
		*)	D=$(umenu "$@") || return
			D=${D%%\|*}
			;;
	esac
	print "$D"
} # }}}1
### prj sub-commands
function subcmd-inc { # {{{1
	local began clients type alias summary details errs unixtm

	[[ -d $PRJFLDR/$1 ]]|| die "No such project ^B$1^b."
	needs-file -or-die $PRJFLDR/$1/PROJECT
	(($#==1))||
		die "Too many parameters to ^Tinc^t sub-command." 'Expected one (1).'

	alias=$1
	parse-project-file <$PRJFLDR/$1/PROJECT ||
		die "Cannot incorporate project ^B$1^b."

	sparkle-path $PRJFLDR/$1/PROJECT
	sPRJPATH=$REPLY

	cat <<-===
	 ┌────────────────────────────────────────────────────────────────────────
	 │ alias:   $alias
	 │ began:   $began
	 │ clients: $clients
	 │ type:    $type
	 │ summary: $summary

	===

	errs=0; s=''
	verify-began	|| ((errs++))
	verify-alias	|| ((errs++))
	verify-type		|| ((errs++))
	((errs>1))&& s=s
	((errs==0))|| die "Bad format$s in $sPRJPATH."

} # }}}1
function show-project-summaries { # {{{1
	local fmt fmt_raw fmt_sprkld
	fmt_raw='%s\t%s%s\n'
	fmt_sprkld='  ^B^T%s^t ^N%s^n^b%s\n'
	[[ ${1:-} == raw ]]&& fmt=$fmt_raw || fmt=$fmt_sprkld
	awk -v fmt="$fmt" -f /dev/stdin $PRJFLDR/*/PROJECT <<-\
		\===AWK===
		function prnsummary(s,n,y,i,nm) {
				i = index($2,":")
				if (i>0) {
					nm = substr(s,1,i-1)
					s = substr(s,i+1)
				  }
				n = split(FILENAME,y,"/");
				printf(fmt, y[n-1], nm, s);
			}
		BEGIN { FS = " +\\| +" }
		$1 == "summary" {
				prnsummary($2)
				nextfile
			}
		===AWK===
} # }}}1
function subcmd-ls { # {{{1
	show-project-summaries "${1:-sparkle}" |sparkle
} # }}}1
function subcmd-help { # {{{1
	usage
} # }}}1
function subcmd-new { # {{{1
	NOT-IMPLEMENTED
} # }}}1

needs needs-file needs-path NOT-IMPLEMENTED SQL SQLify sparkle-path

TAB='	'
NL='
'
PRJFLDR=${HOME:?}/projects
PRJDB=$PRJFLDR/projects.db3
needs-path -create -or-die "$PRJFLDR"

SQL "ATTACH '$PRJDB' AS prj;"
SQL 'SELECT COUNT(*) FROM prj.projects;'
((${sqlreply[*]+1}))||
	die "Unknown problem reading ^B$PRJDB^b."
[[ $sqlreply == +([0-9]) ]]|| create-db

if [[ $1 == @(help|inc|ls|new) ]]; then
	CMD=$1; shift
	"subcmd-$CMD" "$@"
else
	[[ $1 == \! ]]&& shift
	search "$@"
fi; exit

# Copyright (C) 2023 by Tom Davis <tom@greyshirt.net>.
