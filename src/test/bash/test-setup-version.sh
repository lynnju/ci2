#!/bin/bash -u

# Test framework
. ${TEST_PATH}/wvtest.sh
. ${MAIN_PATH}/lib-ci

MYTMPDIR=$( Mktemp_Portable dir ${PWD} )
cd $MYTMPDIR

echo "1.0.0" > VERSION

versionOrig=$(cat VERSION)
# Check command works
WVPASS ${MAIN_PATH}/setup-version.sh
# Check command modifies version
WVPASSNE "$(cat VERSION)" "$versionOrig"
# Check command fails properly
rm VERSION
WVFAIL ${MAIN_PATH}/setup-version.sh

rm -rf $MYTMPDIR
