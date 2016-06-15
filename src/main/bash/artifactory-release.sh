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


set -o pipefail

# Library import helper
function import() {
    IMPORT_PATH="${BASH_SOURCE%/*}"
    if [[ ! -d "$IMPORT_PATH" ]]; then IMPORT_PATH="$PWD"; fi
    . $IMPORT_PATH/$1
    [ $? != 0 ] && echo "$1 import error" 1>&2 && exit 1
}

import lib-ci

CI_Env_Adapt $(CI_Env_Get)

if [ $(Is_Release) != 0 ]; then
    echo "$0: Not a release branch; Not publishing. (See lib-ci:Is_Release)"
    exit 0
fi

REPO_PATH=$1
ARTIFACT=$2
METADATA=$3

ARTIFACTORY_URL=${ARTIFACTORY_URL:-"https://commbank.artifactoryonline.com/commbank"}
ARTIFACTORY_API_KEY=${ARTIFACTORY_API_KEY?"environment variable is not set"}

if [ -z "$REPO_PATH" ] || [ -z "$ARTIFACT" ]; then
    echo "Upload an artifact to an Artifactory repository."
    echo "usage: $0 repo/path /local/path/to/artifact [meta1=val;meta2=val]"
    exit 1
else 
    echo "REPO_PATH=[${REPO_PATH}] - ARTIFACT=[${ARTIFACT}]"
fi

ARTIFACTORY_AUTH="X-JFrog-Art-Api: $ARTIFACTORY_API_KEY"
ARTIFACT_NAME=$(basename "$ARTIFACT")

status=$(curl --silent --output /dev/null --write-out "%{http_code}" \
        -H "$ARTIFACTORY_AUTH" \
        "$ARTIFACTORY_URL/api/storage/$REPO_PATH/$ARTIFACT_NAME")

if [ "$status" = "404" ]; then

    echo "Uploading '$ARTIFACT_NAME':"
    curl \
        -H "$ARTIFACTORY_AUTH" \
        -T "$ARTIFACT" \
        "$ARTIFACTORY_URL/$REPO_PATH/$ARTIFACT_NAME;$METADATA" || exit 1

elif [ "$status" = "200" ]; then
    echo "Error: Artifact named '$ARTIFACT_NAME' already exists!"
    exit 1
else
    echo "Error: Failed to determine artifact status of '$ARTIFACT_NAME' [$status]"
    exit 1
fi

