#!/bin/bash -u
# Test the sbt-ci-deploy script. This is not comprehensive, but checks the logic
# of when and how it should deploy things.

# Test framework
. ${TEST_PATH}/wvtest.sh
. ${MAIN_PATH}/lib-ci

ORIG_PATH=$PATH

TMPPATH=$( Mktemp_Portable dir )
export PATH=$TMPPATH:$ORIG_PATH

# Setup a fake sbt path
touch $TMPPATH/sbt
chmod +x $TMPPATH/sbt

# Check failure scenarios
WVFAIL ${MAIN_PATH}/sbt-ci-deploy.sh
WVFAIL ${MAIN_PATH}/sbt-ci-deploy.sh maven
WVFAIL ${MAIN_PATH}/sbt-ci-deploy.sh maven http://someurl
WVFAIL ${MAIN_PATH}/sbt-ci-deploy.sh unsupported http://someurl somerepo

# Check we don't try to publish on non-master but do return success
REAL_CI_BRANCH=$CI_BRANCH
export CI_BRANCH=do-not-publish
WVPASS ${MAIN_PATH}/sbt-ci-deploy.sh maven http://someurl somerepo
WVPASS ${MAIN_PATH}/sbt-ci-deploy.sh ivy http://someurl somerepo

# Setup a fake sbt binary to confirm release behavior
cat << EOF > $TMPPATH/sbt
#!/bin/bash
# This is a fake sbt binary for testing purposes. It always succeeds.
echo "fake-sbt: \$@"
exit 0
EOF

# Check we invoke sbt successfully in both scenarios
export CI_BRANCH=master
WVPASS ${MAIN_PATH}/sbt-ci-deploy.sh maven http://someurl somerepo
WVPASS ${MAIN_PATH}/sbt-ci-deploy.sh maven http://someurl somerepo project1 project2 project3
WVPASS ${MAIN_PATH}/sbt-ci-deploy.sh ivy http://someurl somerepo
WVPASS ${MAIN_PATH}/sbt-ci-deploy.sh ivy http://someurl somerepo project1 project2 project3

rm -rf $TMPPATH
