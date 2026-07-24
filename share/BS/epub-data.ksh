#!/bin/ksh
# <@(#)tag:tw.lukas.uberbaud.foo,2026-01-08,19.19.18z/22c7d31>
# vim: ft=ksh ts=4 tw=72 noexpandtab nowrap foldmethod=marker

set -o nounset;: "${FPATH:?Run from within KSH}"

DB=bookshelf.db3
NL='
' # ^capture newline

deflist='title relation creator subject publisher date'
elements=
# Usage {{{1
this_pgm=${0##*/}
function usage {
	desparkle "$this_pgm" PGM
	sparkle >&2 <<-\
	===SPARKLE===
	^F{4}Usage^f: ^T$PGM^t ^[^T-cdfprst^t^] ^Uepub-file^u
	         Prints Dublin Core metadata from ^Bopf^b file in ^Izipped^i ^Uepub-file^u.
	            ^T-D^t  Store metadata in ^O\$^o^VBOOKSHELF^v^O/^o^T$DB^t
	            ^T-a^t  Show all but file (default unless data storage is selected).
	            ^T-c^t  Show ^Bcreator^b.
	            ^T-d^t  Show ^Bdate^b.
	            ^T-f^t  Show ^Bfile^b.
	            ^T-p^t  Show ^Bpublisher^b.
	            ^T-r^t  Show ^Brelation^b.
	            ^T-s^t  Show ^Bsubject^b.
	            ^T-t^t  Show ^Btitle^b.
	         ^GNote: elements are shown in the order the flags are given but not^g
	                 ^Gduplicated, so if^g ^T-a^t ^Gis given last, any left over^g
	                 ^Gelements will be given.^g
	       ^T$PGM -h^t
	         Show this help message.
	===SPARKLE===
	exit 0
} # }}}
function add-element { # {{{1
	[[ $elements == *$1* ]]|| elements=${elements:+$elements }$1;
} # }}}
# process -options {{{1
store_info=false
while getopts :Dacdfhprst Option; do
	case $Option in
		D)	store_info=true;												;;
		a)	for e in $deflist; do add-element $e; done;						;;
		c)	add-element creator;											;;
		d)	add-element date;												;;
		f)	add-element file;												;;
		h)	usage;															;;
		p)	add-element publisher;											;;
		r)	add-element relation;											;;
		s)	add-element subject;											;;
		t)	add-element title;												;;
		\?)	die USAGE "Invalid option: ^B-$OPTARG^b.";						;;
		:)	die USAGE "Option ^B-$OPTARG^b requires an argument.";			;;
		*)	bad-programmer "No getopts action defined for ^T-$Option^t.";	;;
	esac
done
# remove already processed arguments
shift $((OPTIND-1))
# ready to process non '-' prefixed arguments
# /options }}}1
function store-element { # {{{1
	NOT-IMPLEMENTED -die
} # }}}1
function show-element { # {{{1
	typeset -L12 k=$1:
	print -r -- "  $k $2"
} # }}}1
function set-date { # {{{1
	[[ $1 == 0101-01-01T00:00* ]]|| date=$1
} # }}}1
function set-meta-element-var { # {{{1
	local IFS key val
	IFS='>'; set -- $1
	val=${2:-}
	IFS=' '; set -- ${1#<dc:}
	typeset -l key=$1
	case $key in
		date*|created)	set-date "$val";							;;
		title*)			title=${title:+$title; }$val;				;;
		relation*)		relation=${relation:+$relation; }$val;		;;
		publisher*)		publisher=${publisher:+$publisher; }$val;	;;
		subject*)		subject=${subject:+$subject; }$val;			;;
		creator*)		gsub ' and ' '; ' "$val" val
						gsub ' & '   '; ' "$val" val
						creator=${creator:+$creator; }$val
						;;
	esac
} #}}}1
function clear-info { # {{{1
	file=$1; date=; creator=; title=; relation=; publisher=; subject=
} # }}}1
function handle-info { # {{{1
	local action k v list
	action=$1
	case $action in
		store)	list="file "$deflist;									;;
		show)	list=$elements;											;;
		*)		bad-programmer "Bad handle-info action: ^B$action^b";	;;
	esac

	for k in $list; do
		eval v=\$$k
		[[ -n $v ]]&& $action-element "$k" "$v"
	done
} # }}}1
function main { # {{{1
	local epub o
	epub=$1
	clear-info "$epub"
	# only do the work if we need to
	[[ $store_info = false && $elements == file ]]|| {
		o=$IFS; IFS=$NL
		set -- $(unzip -p "$epub" \*.opf | egrep -o '<dc:[^>]+>[^<]*')
		IFS=$o
		for ln { set-meta-element-var "$ln"; }
	  }
	[[ -n $elements ]]&&	handle-info show
	$store_info	&&			handle-info store
} #}}}1

needs unzip egrep needs-file

(($#))|| die 'Missing required parameter ^Uepub-file^u.'
needs-file -or-die "$1"

$store_info &&
	{ [[ -n ${BOOKSHELF:-} ]]|| die '^O$^o^VBOOKSHELF^v is not set.'; }

# if we're not storing, then show using -a if no 'show' flags were given
$store_info || elements=${elements:-$deflist}
main "$@"; exit

# Copyright (C) 2026 by Tom Davis <tom@greyshirt.net>.
