#!/bin/ksh
# <@(#)tag:tw.csongor.greyshirt.net,2021-09-25,02.16.59z/1111163>

set -u
: ${FPATH:?}
pager=${PAGER:-less}

[[ -n ${1:-} ]]|| die 'Missing required parameter ^Ufile^u.'

needs cat $pager sparkle tput

: ${APP_PATH:?}

HELP_PATH=$APP_PATH/help
needs-path -or-die -no-create "$HELP_PATH"

H=$HELP_PATH/$1
[[ -f $H ]]|| die "Could not find file ^U$1^u."

SCRNLNS=${LINES:-$(tput lines)}
FILELNS=$(wc -l<$H)

((FILELNS<SCRNLNS))&& pager=cat

SPARKLE_FORCE_COLOR=true sparkle <$H |$pager
