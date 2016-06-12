#!/bin/bash -u
# Test the docker-support script.

# Test framework
. ${TEST_PATH}/wvtest.sh
. ${MAIN_PATH}/lib-ci

# get_CI_env tests
CI_SYSTEM=$(CI_Env_Get)

ORIG_PATH=$PATH

MYTMPDIR=$( Mktemp_Portable dir ${PWD} )
MYTMPPATH=$( Mktemp_Portable dir ${PWD} )

echo MYTMPPATH=$MYTMPPATH

#--------------------- Setup Fake environment -------------
# docker-support will call scripts in this directory
export CI_DIR=$MYTMPDIR
cd $MYTMPDIR
export PATH=$MYTMPPATH:$ORIG_PATH

#
# get a few things
#
touch ci-publish-site.sh 
chmod +x ci-publish-site.sh

#----------------------------------------------------
# Setup - create a fake docker binary to check the command invocation
#----------------------------------------------------

# Setup a fake docker path
touch $MYTMPPATH/docker
chmod +x $MYTMPPATH/docker
export HOME=${MYTMPDIR}

#
#
cat << EOF > $MYTMPPATH/docker
#!/bin/bash
# This is a fake docker binary for testing purposes.
echo "fake-docker: \$@"
MODE=\$1
if [[ "\$MODE" == "login" ]]; then 
  echo "fake login >> \$HOME/.docker/config.json"
  [ -d \$HOME/.docker ] || mkdir \$HOME/.docker
  echo \$REGISTRY_HOST > \$HOME/.docker/config.json
fi
echo \$@ > $MYTMPDIR/TEST_docker-\$MODE
EOF

#
#
cat << EOF > ci-publish-site.sh
#!/bin/bash
echo "fake-site-publish: \$@"
echo \$@ > $MYTMPDIR/TEST_ci-publish-site
EOF

#--------------------- Perform Tests -------------
# Check the script fails properly
#----------------------------------------------------

WVFAIL ${MAIN_PATH}/docker-support.sh
WVFAIL ${MAIN_PATH}/docker-support.sh unsupported

#----------------------------------------------------
# setup - test artefact version file
#----------------------------------------------------

echo "1.2.3" > VERSION
versionOrig=$( cat VERSION )

#----------------------------------------------------
# Invalid VAR check tests
#----------------------------------------------------
# these should fail because a few environment vars are not setup

WVFAIL ${MAIN_PATH}/docker-support.sh setup 
WVFAIL ${MAIN_PATH}/docker-support.sh publish

# now let's get specific
# ---- setup tests
WVFAIL ${MAIN_PATH}/docker-support.sh setup 
export REGISTRY_HOST=someserver.foobar
WVFAIL ${MAIN_PATH}/docker-support.sh setup 
export DOCKER_IMAGE=build/my-special-docker
WVPASS ${MAIN_PATH}/docker-support.sh setup 


# user/pass for a login
WVFAIL ${MAIN_PATH}/docker-support.sh setup -l
export REGISTRY_USERNAME=user
WVFAIL ${MAIN_PATH}/docker-support.sh setup -l
export REGISTRY_PASSWORD=user
export CI_EMAIL=some_email@somewhere.com.foo
WVPASS ${MAIN_PATH}/docker-support.sh setup -l

# ---- publish tests
#
# Should fail a login
# no file created

#
# given that setup has now passed. Let's simulate the real
CI_Env_Adapt $(CI_Env_Get)

export RELEASE_BRANCHES=${CI_BRANCH}
export CI_PULL_REQUEST=false 
. ./ci-env-vars.sh

#
rm $HOME/.docker/config.json
unset REGISTRY_USERNAME
unset REGISTRY_PASSWORD
WVFAIL ${MAIN_PATH}/docker-support.sh publish
WVPASS [ ! -f $HOME/.docker/config.json ]

#
# Should succeed a login
#
export REGISTRY_USERNAME=user
export REGISTRY_PASSWORD=password
WVPASS ${MAIN_PATH}/docker-support.sh publish 
WVPASS [ -f $HOME/.docker/config.json ]

WVFAIL ${MAIN_PATH}/docker-support.sh publish -s
export CI_USERNAME=mygituser
WVPASS ${MAIN_PATH}/docker-support.sh publish -s

# ^^ all env vars are setup now, so it will work in the next run

# ensure that no _site/config.yml was created at this stage 
# There is no _site dir at this juncture
WVPASS [ ! -f $MYTMPDIR/_site/config.yml ]

#----------------------------------------------------
# test - perform the setup but no login should have occurred
#----------------------------------------------------

rm $MYTMPDIR/TEST_docker-login
rm $HOME/.docker/config.json
WVPASS ${MAIN_PATH}/docker-support.sh setup
# make sure that login was not attempted
WVPASS [ ! -f $MYTMPDIR/TEST_docker-login ]
WVPASS [ ! -f $HOME/.docker/config.json ]

#----------------------------------------------------
# test - Was docker login called ? 
#----------------------------------------------------
WVPASS ${MAIN_PATH}/docker-support.sh setup -l
dockerArgs=( $(cat $MYTMPDIR/TEST_docker-login) )
expected=(\
    "login" \
    "-u" \
    "${REGISTRY_USERNAME}" \
    "-p" \
    "${REGISTRY_PASSWORD}" \
    "-e" \
    "${CI_EMAIL}" \
    "${REGISTRY_HOST}" \
)
WVPASSEQ "$(echo ${dockerArgs[@]})" "$(echo ${expected[@]})"
WVPASS [ -f $HOME/.docker/config.json ]

#----------------------------------------------------
# test - calling docker-support.sh calls creates  VERSION file .. so that should have happened
#        Check command modifies version
#----------------------------------------------------

versionNew=$( cat VERSION )
WVPASSNE "$versionNew" "$versionOrig"

#----------------------------------------------------
# test - the setup creates an environments file for .drone.yml .travis.yml import (. ./ci-env-vars.sh )
#        let's check it
#----------------------------------------------------

WVPASS [ -f ci-env-vars.sh ]
envVars=( $(cat ci-env-vars.sh) )
expected=(\
    "#!/bin/bash" \
    "export REGISTRY_HOST=${REGISTRY_HOST}" \
    "export VERSION=${versionNew}" \
    "export DOCKER_IMAGE=${DOCKER_IMAGE}" \
    "export DOCKER_TAG_NAME=${REGISTRY_HOST}/${DOCKER_IMAGE}:${versionNew}" \
)
WVPASSEQ "$(echo ${envVars[@]})" "$(echo ${expected[@]})"

#----------------------------------------------------
# test - docker-support.sh publish will call 'docker push ${DOCKER_TAG_NAME}' - but only on a release branch
#        so we will test that - we have the fake docker shell script going
#----------------------------------------------------

# for the test
. ./ci-env-vars.sh
export ${CI_SYSTEM}_BRANCH=master
export ${CI_SYSTEM}_PULL_REQUEST=false
mkdir _site

WVPASS ${MAIN_PATH}/docker-support.sh publish -s
pushArgs=( $(cat $MYTMPDIR/TEST_docker-push) )
expected=(\
    "push" \
    "${REGISTRY_HOST}/${DOCKER_IMAGE}:${versionNew}" \
)
WVPASSEQ "$(echo ${pushArgs[@]})" "$(echo ${expected[@]})"

#----------------------------------------------------
# test - docker-support.sh will call ci-publish-site,bsh .. so lets make sure that was called
#----------------------------------------------------

sitePublish=(  $( cat $MYTMPDIR/TEST_ci-publish-site ) )
expected=( "_site" )
WVPASSEQ "$(echo ${sitePublish[@]})" "$(echo ${expected[@]})"

# check that docker-support wrote out the various vars
siteConfigVars=( $(cat _site/_config.yml) )
expected=(\
    "dockerTagName: ${REGISTRY_HOST}/${DOCKER_IMAGE}:${versionNew}" \
    "dockerImage: ${DOCKER_IMAGE}" \
    "dockerImageFull: ${REGISTRY_HOST}/${DOCKER_IMAGE}" \
    "registryHost: ${REGISTRY_HOST}"
)
WVPASSEQ "$(echo ${siteConfigVars[@]})" "$(echo ${expected[@]})"

#----------------------------------------------------
# should not publish if not passed a -s
#----------------------------------------------------
rm $MYTMPDIR/TEST_ci-publish-site
WVPASS ${MAIN_PATH}/docker-support.sh publish 
WVPASS [ ! -f $MYTMPDIR/TEST_ci-publish-site ]

#----------------------------------------------------
# test - check rmi was called
#----------------------------------------------------

dockerRmiArgs=( $(cat $MYTMPDIR/TEST_docker-rmi) )
expected=(\
    "rmi" \ 
    "${DOCKER_TAG_NAME}" \
)
WVPASSEQ "$(echo ${dockerRmiArgs[@]})" "$(echo ${expected[@]})"

#----------------------------------------------------
# Cleanup
#----------------------------------------------------
cd ..
rm -rf $MYTMPPATH $MYTMPDIR 

echo "-------------- END $0"
