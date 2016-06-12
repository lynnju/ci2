#!/bin/bash -u
# Test the dockermake script.

# Test framework
. ${TEST_PATH}/wvtest.sh
. ${MAIN_PATH}/lib-ci


ORIG_PATH=$PATH
SCRIPT_DIR=${MAIN_PATH}

MYTMPDIR=$( Mktemp_Portable dir ${PWD} )
TMPPATH=$( Mktemp_Portable dir ${PWD} )

export PATH=$TMPPATH:$ORIG_PATH

# Setup a fake docker path
touch $TMPPATH/docker
chmod +x $TMPPATH/docker

WORKDIR=$( Mktemp_Portable dir ${PWD} )

cd $WORKDIR

# Check the script fails properly
WVFAIL ${SCRIPT_DIR}/dockermake.sh
WVFAIL ${SCRIPT_DIR}/dockermake.sh unsupported

# Test docker build part
mkdir tmpDOCKERIMAGE
touch tmpDOCKERIMAGE/Dockerfile

mkdir tmpDOCKERIMAGE2
touch tmpDOCKERIMAGE2/Dockerfile

export PREFIX=PREFIX
export http_proxy=fakeproxy

# Setup a fake docker binary to check the command invocation
cat << EOF > $TMPPATH/docker
#!/bin/bash
# This is a fake docker binary for testing purposes.
echo "fake-docker: \$@"
for i in \$@; do
    dest=result_\$i
done
echo \$@ > $MYTMPDIR/\$dest
EOF

# Do a build then check the file fake-docker writes to see what the input args
# were.
WVPASS ${SCRIPT_DIR}/dockermake.sh build --build-arg=somearg1=somevalue1 \
        --build-arg somearg2=somevalue2

# Image 1
dockerArgs=( $(cat $MYTMPDIR/result_tmpDOCKERIMAGE) )

expected=(\
    "build" \
    "--build-arg=http_proxy=fakeproxy" \
    "--build-arg=https_proxy=fakeproxy" \
    "--build-arg=ftp_proxy=fakeproxy" \
    "--build-arg=somearg1=somevalue1" \
    "--build-arg" \
    "somearg2=somevalue2" \
    "-t" \
    "PREFIXtmpDOCKERIMAGE:$(cat VERSION)" \
    "tmpDOCKERIMAGE" \
)

WVPASSEQ "$(echo ${dockerArgs[@]})" "$(echo ${expected[@]})"

# Image 2
dockerArgs=( $(cat $MYTMPDIR/result_tmpDOCKERIMAGE2) )

expected=(\
    "build" \
    "--build-arg=http_proxy=fakeproxy" \
    "--build-arg=https_proxy=fakeproxy" \
    "--build-arg=ftp_proxy=fakeproxy" \
    "--build-arg=somearg1=somevalue1" \
    "--build-arg" \
    "somearg2=somevalue2" \
    "-t" \
    "PREFIXtmpDOCKERIMAGE2:$(cat VERSION)" \
    "tmpDOCKERIMAGE2" \
)

WVPASSEQ "$(echo ${dockerArgs[@]})" "$(echo ${expected[@]})"

# Test building images in the order they are specified on the command line
# and also only the command line specified ones.
TMPPATHORDER=$( Mktemp_Portable dir ${PWD} )
export PATH=$TMPPATHORDER:$ORIG_PATH

# Pre-req
mkdir tmpDOCKERIMAGEyyy
touch tmpDOCKERIMAGEyyy/Dockerfile

# Dependant
mkdir tmpDOCKERIMAGExxx
touch tmpDOCKERIMAGExxx/Dockerfile

# Setup a fake docker binary which fails if the pre-req doesn't exist
cat << EOF > $TMPPATHORDER/docker
#!/bin/bash
# Check if the pre-req file generated first
[ "\$7" = "tmpDOCKERIMAGExxx" ] && [ ! -e "$MYTMPDIR/result_tmpDOCKERIMAGEyyy" ] && exit 1

# This is a fake docker binary for testing purposes.
echo "fake-docker: \$@"
echo \$@ > $MYTMPDIR/result_\$7
exit 0
EOF
chmod +x $TMPPATHORDER/docker

WVPASS ${SCRIPT_DIR}/dockermake.sh build tmpDOCKERIMAGEyyy tmpDOCKERIMAGExxx

cd ..

rm -rf $TMPPATH $MYTMPDIR $TMPPATHORDER $WORKDIR
