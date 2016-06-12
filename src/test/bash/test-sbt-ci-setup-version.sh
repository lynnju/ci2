#!/bin/bash -u

# Test framework
. ${TEST_PATH}/wvtest.sh
. ${MAIN_PATH}/lib-ci

MYTMPDIR=$( Mktemp_Portable dir ${PWD} )
echo -e "version in ThisBuild := \"1.0.0\"\nuniqueVersionSettings" > $MYTMPDIR/version.sbt
cd $MYTMPDIR


versionOrig=$(cat version.sbt)
# Check command works
WVPASS ${MAIN_PATH}/sbt-ci-setup-version.sh
# Check command modifies version
WVPASSNE "$(cat version.sbt)" "$versionOrig"
# Check input string comes out broadly correctly.
WVPASS grep -oE "version in ThisBuild := \"1.0.0.*?\"" version.sbt
# Check file has only a single line in it (version string above)
WVPASSEQ   $(cat version.sbt | wc -l)  1
# Check command fails properly
rm version.sbt
WVFAIL ${MAIN_PATH}/sbt-ci-setup-version.sh

rm -rf $MYTMPDIR
