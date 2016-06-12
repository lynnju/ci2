#!/bin/bash
# Test the ci-publish-site script.

# Test framework
. ${TEST_PATH}/wvtest.sh
. ${MAIN_PATH}/lib-ci

SCRIPTS_DIR=${MAIN_PATH}

# This is our fake remote repo to send documentation to
TMPREMOTE=$( Mktemp_Portable dir )
atexit '[ ! -z "$TMPREMOTE" ] && rm -rf $TMPREMOTE'
git init --bare $TMPREMOTE || exit 1

# Base directory for test
TMPBASE=$( Mktemp_Portable dir )
atexit '[ ! -z "$TMPBASE" ] && rm -rf $TMPBASE'

# Setup a test git repository in here.
cd $TMPBASE || exit 1
atexit cd $(pwd)

touch .gitkeep
mkdir site
touch site/.gitkeep

git init $TMPBASE || exit 1
git config user.email "zbi+test@cba.com.au"
git config user.name "WVTEST"
git add -A || exit 1
git commit -m "Initial commit" || exit 1
git symbolic-ref HEAD refs/heads/master || exit 1
git remote add origin $TMPREMOTE || exit 1

cd $TMPBASE || exit 1
atexit cd $(pwd)

# Check we fail when no VERSION
WVFAIL ${SCRIPTS_DIR}/ci-publish-site.sh "$TMPBASE/site" "gh-pages" "Commit Msg"

# Check fail when empty VERSION
touch VERSION
WVFAIL ${SCRIPTS_DIR}/ci-publish-site.sh "$TMPBASE/site" "gh-pages" "Commit Msg"

# Should pass when a version file exists and the CI_USERNAME and CI_EMAIL
export CI_EMAIL="zbi+test@cba.com.au"
export CI_USERNAME="WVTEST"
echo "1.0.0" >> VERSION
WVPASS ${SCRIPTS_DIR}/ci-publish-site.sh "$TMPBASE/site" "gh-pages" "Commit Msg"

# Check the we end up with something sensible in the base directory
WVPASS [ -e "$TMPBASE/site/_config.yml" ]
WVPASS grep 'releaseVersion' $TMPBASE/site/_config.yml

# Do a bunch of WVFAIL tests for command line parsing 
WVFAIL ${SCRIPTS_DIR}/ci-publish-site.sh nonexistent
WVFAIL ${SCRIPTS_DIR}/ci-publish-site.sh

