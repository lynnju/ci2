#!/bin/bash -u

# Test framework
. ${TEST_PATH}/wvtest.sh

. ${MAIN_PATH}/lib-ci

TMPWORKDIR=$( Mktemp_Portable dir )

cp -a ${TEST_PATH}/test-bump-versions/scala/. ${TMPWORKDIR}

cd ${TMPWORKDIR}
echo "[$0] - working in ${TMPWORKDIR}"

# project/build.sbt
WVPASS ${MAIN_PATH}/bump-scala-version-depend.sh "omnia" "omnia-test" "2.0"
WVPASS grep '  depend.omnia("omnia-test", "2.0") ++' build.sbt

