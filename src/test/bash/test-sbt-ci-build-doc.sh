#!/bin/bash
# Test the sbt-ci-build-doc. To do this, we import a very simple sbt project
# (included in this repository) and build documentation against it.

# Test framework
. ${TEST_PATH}/wvtest.sh
. ${MAIN_PATH}/lib-ci

# Base dir for sbt
TMPBASE=$( Mktemp_Portable dir )

# This is our fake remote repo to send documentation to
TMPREMOTE=$( Mktemp_Portable dir )
git init --bare $TMPREMOTE || exit 1

# cp our sample project over to the TMPBASE
cp -av $TEST_PATH/test-sbt-ci-build-doc ${TMPBASE}
cd $TMPBASE/test-sbt-ci-build-doc

ORIG_CI_BRANCH=$CI_BRANCH

# We need to do some setup - namely, turning the test fixture root into a
# git repository. sbt-ci-build-doc will then operate on this repo in a
# subdirectory.
git init . || exit 1
git config user.email "zbi+test@cba.com.au"
git config user.name "WVTEST"
git add -A || exit 1
git commit -m "Initial commit" || exit 1
git symbolic-ref HEAD refs/heads/master || exit 1

# Test that we fail when there is no git remote.
export FORCE_PUBLISH=yes
WVFAIL ${MAIN_PATH}/sbt-ci-build-doc.sh "http://testroot" "http://testsourceroot"

# Make a git remote to allow the script to find one
git remote add origin $(readlink_f $TMPREMOTE) || exit 1

# This should now run correctly.
WVPASS ${MAIN_PATH}/sbt-ci-build-doc.sh "http://testroot" "http://testsourceroot"

# Remove temporary directories
rm -rf .gitkeep .git $TMPBASE $TMPREMOTE

