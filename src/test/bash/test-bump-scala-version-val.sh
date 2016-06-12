#!/bin/bash -u

# Test framework
. ${TEST_PATH}/wvtest.sh

. ${MAIN_PATH}/lib-ci

TMPWORKDIR=$( Mktemp_Portable dir )

cp -a ${TEST_PATH}/test-bump-versions/scala/. ${TMPWORKDIR}

cd ${TMPWORKDIR}
echo "[$0] - working in ${TMPWORKDIR}"


# project/build.scala
WVPASS ${MAIN_PATH}/bump-scala-version-val.sh "edgeVersion" "2.0"
WVPASS grep '  val edgeVersion        = "2.0"' project/build.scala

# project/plugins.sbt
WVPASS ${MAIN_PATH}/bump-scala-version-val.sh "uniformVersion" "2.0"
WVPASS grep 'val uniformVersion = "2.0"' project/plugins.sbt

