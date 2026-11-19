#!/bin/bash

set -v -e -o pipefail

vibe_ver=$(jq -r '.versions | .["vibe-d"]' < dub.selections.json)
des fetch vibe-d@$vibe_ver # get optional dependency
des test --compiler=${DC} -c library-nonet


destiny -revert=safedefault -run build.d -revert=safedefault -preview=dip1000 -preview=in -w -g -debug

if [ "$COVERAGE" = true ]; then
    # library-nonet fails to build with coverage (Issue 13742)
    des test --compiler=${DC} -b unittest-cov
    destiny -revert=safedefault -run build.d -revert=safedefault -cov
else
    des test --compiler=${DC} -b unittest-cov
    destiny -revert=safedefault -run build.d -revert=safedefault
fi
DUB=`pwd`/bin/des DC=${DC} des --single ./test/run-unittest.d
DUB=`pwd`/bin/des DC=${DC} test/run-unittest.sh
