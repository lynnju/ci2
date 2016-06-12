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

# sbt-ci-deploy.sh (maven|ivy) targetUrl targetRepository [ project1 project2 ... ]
#
#   Uses sbt to deploy artifacts to the chosen target repository. Optionally,
#   projects can be named explicitly in order that sbt deploy each of them
#   to the chosen repository. This deploys artifacts using ivy style. This
#   is mainly used for sbt plugins.
#
#   targetRepository - the target repository for deployment
#                      (eg. ext-releases-local or libs-releases-local)
#   projectN - a project name for sbt to deploy. If this is omitted, the
#              default (top-level) project is deployed.
#
#   You need to supply artifactory credentials as the environment variables
#   ARTIFACTORY_USERNAME and ARTIFACTORY_PASSWORD.

set -u

# Library import helper
function import() {
    IMPORT_PATH="${BASH_SOURCE%/*}"
    if [[ ! -d "$IMPORT_PATH" ]]; then IMPORT_PATH="$PWD"; fi
    . $IMPORT_PATH/$1
    [ $? != 0 ] && echo "$1 import error" 1>&2 && exit 1
}

import lib-ci

CI_Env_Adapt $(CI_Env_Get)

SBT=$(which_sbt) || exit 1

# Gather the required parameters
publishStyle=$1
shift
artifactoryURL=$1
shift
targetRepository=$1
shift

# Validate
case "$publishStyle" in
    maven|ivy)
        echo "Publishing as $publishStyle"
        ;;
    *)
        echoerr "Invalid publication style. Must be maven or ivy. Exiting with error."
        exit 1
        ;;
esac


if [ -z "$artifactoryURL" ]; then
    echoerr "No artifactory URL specified. Exiting with error."
    exit 1
fi

if [ -z "$targetRepository" ]; then
    echoerr "No target repository name specified. Exiting with error."
    exit 1
fi

function do_release() {
    cat > sbt.credentials <<EOF
realm=Artifactory Realm
host=$(Hostname_From_Url $artifactoryURL)
user=$ARTIFACTORY_USERNAME
password=$ARTIFACTORY_PASSWORD
EOF

    echo "Publishing to repository $targetRepository"
    echo "Full publishing URL: $artifactoryURL/$targetRepository"
    
    publishTo="set publishTo in ThisBuild := Some(\"$targetRepository\" at \"$artifactoryURL\")"
    case "$publishStyle" in
        maven)
            publishStyleLine="set publishMavenStyle in ThisBuild := true"
            ;;
        ivy)
            publishStyleLine="set publishMavenStyle in ThisBuild := false"
            ;;
        *)
            echoerr "BUG: Publish style should be validated before now."
            exit 1
    esac
    
    credentialsArg="set credentials += Credentials(new java.io.File(\"sbt.credentials\"))"
    
    if [ $# -eq 0 ]; then
        $SBT "$credentialsArg" "$publishTo" "$publishStyleLine" "; + publish"
    else
        for project in $@; do
            echo "Publishing $project ..."
            $SBT ";project $project" "$credentialsArg" "$publishTo" "$publishStyleLine" "; + publish"
        done        
    fi
}

if [ "$(Is_Release)" = "0" ]; then
    do_release
else 
    echoerr "This is not a release a branch so it will not be deployed".
    echoerr "To make this a release branch, add it to the RELEASE_BRANCHES environment variable."
fi

