#!/bin/bash
#   Copyright 2014 Commonwealth Bank of Australia
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

# Sets up an Omnia compliant version number from a VERSION file in the current
# working directory for use by SBT.

set -u

# Library import helper
function import() {
    IMPORT_PATH="${BASH_SOURCE%/*}"
    if [[ ! -d "$IMPORT_PATH" ]]; then IMPORT_PATH="$PWD"; fi
    . $IMPORT_PATH/$1
    [ $? != 0 ] && echo "$1 import error" 1>&2 && exit 1
}

import lib-ci

if [ ! -f "version.sbt" ]; then
    echo "version.sbt file not found." 1>&2
    exit 1
fi

new_version=$(Version_Get "$(cat version.sbt)")
if [ -z $new_version ]; then
    exit 1
fi

echo "Version Mapped: $version => $new_version"
echo "version in ThisBuild := \"$new_version\"" > version.sbt

exit 0
