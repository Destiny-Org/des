#!/usr/bin/env bash

. $(dirname "${BASH_SOURCE[0]}")/common.sh
unset DFLAGS # Destiny: the CI exports DFLAGS; this test compares exact compiler flags

cd "$CURR_DIR"/describe-project

temp_file=$(mktemp $(basename $0).XXXXXX)

function cleanup {
    rm $temp_file
}

trap cleanup EXIT

if ! $DUB describe --compiler=$DC > "$temp_file"; then
    die $LINENO 'Printing describe JSON failed!'
fi

