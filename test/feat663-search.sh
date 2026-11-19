#!/usr/bin/env bash

. $(dirname "${BASH_SOURCE[0]}")/common.sh
if ${DUB} search 2>/dev/null; then
    die $LINENO '`dub search` succeeded'
fi
if ${DUB} search nonexistent123456789package 2>/dev/null; then
    die $LINENO '`dub search nonexistent123456789package` succeeded'
fi
# Destiny: searches the test registry (test/fixtures/make-fixtures.sh)
if ! OUTPUT=$(${DUB} search 'gitcompatibledubpackage' -v 2>&1); then
    die $LINENO '`des search gitcompatibledubpackage` failed' "$OUTPUT"
fi
if ! grep -q '^\s\sgitcompatibledubpackage (.*)\s'<<<"$OUTPUT"; then
    die $LINENO '`grep -q '"'"'^\s\sgitcompatibledubpackage (.*)\s'"'"'` failed' "$OUTPUT"
fi
