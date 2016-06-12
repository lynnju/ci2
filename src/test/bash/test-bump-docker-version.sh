#!/bin/bash -u

# Test framework
. ${TEST_PATH}/wvtest.sh
. ${MAIN_PATH}/lib-ci
TMPWORKDIR=$( Mktemp_Portable dir )
cp -a ${TEST_PATH}/test-bump-versions/docker/. ${TMPWORKDIR}
cd ${TMPWORKDIR}
echo "[$0] - working in ${TMPWORKDIR}"

#--- The Tests
WVPASS ${MAIN_PATH}/bump-docker-version.sh host.com:80/group/test 2
WVPASS grep "host.com:80/group/test:2" Dockerfile

WVPASS ${MAIN_PATH}/bump-docker-version.sh test 2
WVPASS grep "test:2" test/Dockerfile

