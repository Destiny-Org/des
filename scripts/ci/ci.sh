#!/bin/bash

set -v -e -o pipefail

# Destiny: the optional vibe-d integration is tested again once the vibe
# packages in Destiny-Org/packages pass Destiny's safety checks.
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
# The integration tests download from a local test registry (no network
# for test packages), then from Destiny-Org/packages for real ones.
export DUB_REGISTRY="$(bash test/fixtures/make-fixtures.sh);destiny+https://github.com/Destiny-Org/packages"
DUB=`pwd`/bin/des DC=${DC} des --single ./test/run-unittest.d
DUB=`pwd`/bin/des DC=${DC} test/run-unittest.sh
