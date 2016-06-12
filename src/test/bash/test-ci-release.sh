#!/bin/bash -u
# Test the ci-release script.

# Test framework
. ${TEST_PATH}/wvtest.sh
. ${MAIN_PATH}/lib-ci

# get_CI_env tests
CI_SYSTEM=$(CI_Env_Get)

TMPFILE=$( Mktemp_Portable file )

# Tests that the command will be run on release branches
export ${CI_SYSTEM}_BRANCH=master
export ${CI_SYSTEM}_PULL_REQUEST=false
WVPASS ${MAIN_PATH}/ci-release.sh touch $TMPFILE
WVPASS test -e $TMPFILE
rm $TMPFILE

# Tests that the command will not be run on release branches
export ${CI_SYSTEM}_BRANCH=testbranch
export ${CI_SYSTEM}_PULL_REQUEST=false
WVPASS ${MAIN_PATH}/ci-release.sh touch $TMPFILE
WVFAIL test -e $TMPFILE
