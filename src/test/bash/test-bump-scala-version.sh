#!/bin/bash -u

# Test framework
. ${TEST_PATH}/wvtest.sh

. ${MAIN_PATH}/lib-ci

TMPWORKDIR=$( Mktemp_Portable dir )

cp -a ${TEST_PATH}/test-bump-versions/scala/. ${TMPWORKDIR}

cd ${TMPWORKDIR}
echo "[$0] - working in ${TMPWORKDIR}"

# build.sbt
WVPASS ${MAIN_PATH}/bump-scala-version.sh "com.wix" "accord-specs2-3-x" "1.0"
WVPASS grep '    "com.wix"       %% "accord-specs2-3-x"  % "1.0" % "test"' build.sbt

# project/build.scala
WVPASS ${MAIN_PATH}/bump-scala-version.sh "org.apache.commons" "commons-lang3" "4.0"
WVPASS grep '          , "org.apache.commons"     %  "commons-lang3"            % "4.0"' project/build.scala

# project/plugins.sbt
WVPASS ${MAIN_PATH}/bump-scala-version.sh "au.com.cba.omnia" "humbug-plugin" "1.0"
WVPASS grep 'addSbtPlugin("au.com.cba.omnia" % "humbug-plugin"      % "1.0")' project/plugins.sbt

