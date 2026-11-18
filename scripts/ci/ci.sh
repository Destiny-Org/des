#!/bin/bash

set -v -e -o pipefail

vibe_ver=$(jq -r '.versions | .["vibe-d"]' < dub.selections.json)
des fetch vibe-d@$vibe_ver # get optional dependency
des test --compiler=${DC} -c library-nonet

export DMD="$(command -v $DMD)"

./build.d -preview=dip1000 -preview=in -w -g -debug

if [ "$COVERAGE" = true ]; then
    # library-nonet fails to build with coverage (Issue 13742)
    des test --compiler=${DC} -b unittest-cov
    ./build.d -cov
else
    des test --compiler=${DC} -b unittest-cov
    ./build.d
fi
DUB=`pwd`/bin/des DC=${DC} des --single ./test/run-unittest.d
DUB=`pwd`/bin/des DC=${DC} test/run-unittest.sh
