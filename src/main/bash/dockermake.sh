#!/bin/bash
# This bash script manages building docker images in a standardized way for the
# CI pipeline.
#
# Default behavior is build all found Dockerfiles. Images are named by their
# containing directory path from the root.
#
# Names may be specified on the command line, if so, the build and push commands
# will be executed sequentially in order.
#
# The image tags are set from either the VERSION file in the current working
# directory, or from the TAG environment variable. Blank tags are not allowed
# and will fail the build. "latest" is explicitely filtered.
#
# RELEASE_BRANCHES environment variable can be set to an array of branches
# for which `docker push` should be allowed to run. By default it is set to
# `master`
# 
# Example Usage:
# ./ci/dockermake.sh build myimage1 myimage2 --build-arg=someval


set -u

# Library import helper
function import() {
    IMPORT_PATH="${BASH_SOURCE%/*}"
    if [[ ! -d "$IMPORT_PATH" ]]; then IMPORT_PATH="$PWD"; fi
    . $IMPORT_PATH/$1
    [ $? != 0 ] && echo "$1 import error" 1>&2 && exit 1
}

import lib-ci

# Get CI system configuration
CI_Env_Adapt $(CI_Env_Get)

# Build arguments to pass to docker build
FLAGS=()
# Requested images to build from command line
IMAGE_REQUESTS=()
# Actual list of images which will be built
TOBUILD=()
# Images which were found as candidates to be built
IMAGES=()

# Check push parameters
if [ -z $RELEASE_BRANCHES ]; then
    RELEASE_BRANCHES=("master")
fi

# Get the action requested.
ACTION=$1
shift

# Extract image arguments until flags
for arg in $1; do
    if [[ "$arg" == -* ]]; then
        break
    fi
    IMAGE_REQUESTS+=("$arg")
    shift
done

# Remainder is flags
FLAGS=("$@")

# Find all the docker images, use the directory structure for their path.
while read i ; do
    IMAGES+=( "$(dirname $i)" )
done < <(find * -name Dockerfile -type f -print | sort)

# Find the images we were requested to build, or build all if none specified.
# Note: this preserves build order to command line order.
if [ ${#IMAGE_REQUESTS[@]} -gt 0 ]; then
    for j in ${IMAGE_REQUESTS[@]}; do
        if [ $(Array_Contains "$j" "${IMAGES[@]}") -eq 0 ]; then
            TOBUILD+=( "$i" )
        fi
    done
else
    TOBUILD=${IMAGES[@]}
fi

# Set tag from environment or version file.
if [ ! -z $TAG ]; then
    TAG=$TAG
else
    TAG=$(cat VERSION)
fi

if [ "$TAG" = "latest" ]; then
    echo "\"latest\" is not allowed as a tag value. Please don't try and use it." 1>&2
    exit 1
fi

do_build() {
    # Discover proxy environment
    if [ -z $https_proxy ]; then
        https_proxy=$http_proxy
    fi

    if [ -z $ftp_proxy ]; then
        ftp_proxy=$http_proxy
    fi

    for i in ${TOBUILD[@]}; do
        docker build ${BUILD_ARGS[@]} \
                     --build-arg=http_proxy=$http_proxy \
                     --build-arg=https_proxy=$http_proxy \
                     --build-arg=ftp_proxy=$http_proxy \
                     ${FLAGS[@]} \
                     -t ${PREFIX}${i}:${TAG} ${i}
         exit_code=$?
         if [ $exit_code != 0 ]; then
            echo "Docker image failed to build, exit status: $exit_code" 1>&2
            exit 1
         fi
    done
}

do_push() {
    if [ $(Is_Release) != 0 ]; then
        echo "$CI_BRANCH is not a release branch. Not pushing." 1>&2
    else
        local image=${PREFIX}${i}:${TAG}
        local failflag=0
        for i in ${TOBUILD[@]}; do
            docker push $image
            local exit=$?
            if [ $exit != 0 ]; then
              echo "Error pushing image: Code $exit $image" 1>&2
              failflag=1
            fi
            docker rmi $image
        done

        if [ $failflag != 0 ]; then
          echo "Some images failed to push. Failing build." 1>&2
          exit 1
        fi
    fi
}

# Options!
echo "Actioning docker images:"
for i in ${TOBUILD[@]}; do
    echo " - ${PREFIX}${i}:${TAG}"
done

case $ACTION in
    push)
        do_push
        ;;
    build)
        do_build
        ;;
    *)
        echo "Must specify either build or push" 1>&2 && exit 1
        exit 1
        ;;
esac
