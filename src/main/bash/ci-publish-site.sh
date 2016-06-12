#!/bin/bash 
#   Copyright 2016 Commonwealth Bank of Australia
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#   Generic CI system documentation publication script. This is designed to be
#   run after setup-version.sh to publish a version number to releaseVersion
#   in _config.yml. Any existing key with this name will be removed.
#   <directory> is relative to the current working directory. The remote pushed
#   to is always 'origin'.
#
#   Usage:
#   ./ci/ci-publish-site.sh <directory> [branch] [commit msg]
#
#   Branch defaults to "gh-pages", commit msg defaults to 
#   "CI Documentation Update"
#
#   Example:
#   ./ci/ci-publish-site.sh _site gh-pages "Automatic Update"
#

# Library import helper
function import() {
    IMPORT_PATH="${BASH_SOURCE%/*}"
    if [[ ! -d "$IMPORT_PATH" ]]; then IMPORT_PATH="$PWD"; fi
    . $IMPORT_PATH/$1
    [ $? != 0 ] && echo "$1 import error" 1>&2 && exit 1
}

import lib-ci

CI_Env_Adapt $(CI_Env_Get)

dir=$(readlink_f ${1?"directory must be supplied"} )
echo "[[[$dir]]]"
branch="$2"
commit_msg="$3"

if [ -z "$dir" ]; then 
    echoerr "Directory cannot be blank."
    exit 1
fi

if [ ! -d "$dir" ]; then
    echoerr "$dir does not exist."
    exit 1
fi

if [ -z "$branch" ]; then
    branch="gh-pages"
fi

if [ -z "$commit_msg" ]; then
    commit_msg="CI Documentation Update"
fi

if [ ! -e VERSION ]; then
    echoerr "VERSION file not found."
    exit 1
fi

version=$(cat VERSION)
if [ -z "$version" ]; then
    echoerr "VERSION file was empty."
    exit 1
fi

CI_EMAIL=${CI_EMAIL?"is not defined"}
CI_USERNAME=${CI_USERNAME?"is not defined"}

echo "" >> $dir/_config.yml
sed -i -e '/^releaseVersion: .*/d' $dir/_config.yml || exit 1
echo "releaseVersion: $version" >> $dir/_config.yml

if [ $CI_BRANCH = "master" ]; then
    git config user.email "${CI_EMAIL}"
    git config user.name "${CI_USERNAME}"
    Publish_Subdirectory_To_Branch $branch "$dir" "$commit_msg"
else
    echoerr "Not publishing because branch is not master."
fi

exit 0
