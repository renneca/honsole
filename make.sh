#!/usr/bin/env zsh

set -o ERR_EXIT
set -o ERR_RETURN
set -o PIPE_FAIL

source ./priv/tool.sh
[[ -e  ./priv/private.sh ]] &&
source ./priv/private.sh

honsole=honsole
h5agent=honsole-webkit
product=$( bundle-prefix ).honsole
version=$( spec-version  )

if [ 0 = $# ]
then
    make-all
else
    $*
fi
