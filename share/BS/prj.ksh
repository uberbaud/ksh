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
	^F{4}Usage^f: ^T$PGM^t
	         Manage projects
	       ^T$PGM -h^t
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
function create-db {
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
}

function main {
	NOT-IMPLEMENTED
}

needs needs-path NOT-IMPLEMENTED SQL SQLify

PRJFLDR=${HOME:?}/projects
PRJDB=$PRJFLDR/projects.db3
needs-path -create -or-die "$PRJFLDR"

SQL "ATTACH '$PRJDB' AS prj;"
SQL 'SELECT COUNT(*) FROM prj.projects;'
((${sqlreply[*]+1}))||
	die "Unknown problem reading ^B$PRJDB^b."
[[ $sqlreply == +([0-9]) ]]|| create-db


main "$@"; exit

# Copyright (C) 2023 by Tom Davis <tom@greyshirt.net>.
