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
# docker-support.sh setup
#   or
# docker-support.sh publish
#
# for more details, see usage below

set -o pipefail

IFS=$'\n\t'
IMPORT_PATH="${BASH_SOURCE%/*}"
if [[ ! -d "$IMPORT_PATH" ]]; then IMPORT_PATH="$PWD"; fi
CI_DIR=${CI_DIR:-${IMPORT_PATH}}

# Library import helper
function import() {
    . $IMPORT_PATH/$1
    [ $? != 0 ] && echo "$1 import error" 1>&2 && exit 1
}

import lib-ci

CI_Env_Adapt $(CI_Env_Get)

function usage() {
  echo "$0 setup | publish <options>" 1>&2
  echo 1>&2
  echo "The two simplest forms are '$0 setup' or '$0 publish'. All other vars are searched on the environment" 1>&2
  echo 1>&2
  echo "setup [-l ] -u <user> -p <password> -e <email> -r <registry_host>" 1>&2
  echo "  -l                     - execute docker login : by default we won't login. just setup VARs" 1>&2
  echo "                         - -l implies that registry credentials are supplied (see next)" 1>&2
  echo "  -u <REGISTRY_USERNAME> - will look for this as ENV VAR REGISTRY_USERNAME by default" 1>&2
  echo "  -p <REGISTRY_PASSWORD> - will look for this as ENV VAR REGISTRY_PASSWORD by default" 1>&2
  echo "  -r <REGISTRY_HOST>     - defaults to ${REGISTRY_HOST}" 1>&2
  echo 1>&2
  echo "publish -e <git-email> -n <git-username> [ -i <user/docker-image> | -d <full-docker-tag> ] [ -s ]"
  echo "  -s                    - publish the site also"
  echo "  -e <CI_EMAIL>        - used for _site doc publish-ing - defaults to ${CI_EMAIL}" 1>&2
  echo "  -n <CI_USERNAME>     - used for _site doc publish-ing - defaults to ${CI_USERNAME}" 1>&2
  echo
  echo "  -i <DOCKER_IMAGE>     - Docker tag .. user/tag" 1>&2
  echo " OR" 1>&2
  echo "  -d <DOCKER_TAG_NAME>  - Docker tag .. registry/user/tag" 1>&2
}


function indent() { 
  echo $@ | sed 's/^/    /';
}

function log() { 
  echo ":: $1"
  shift
  $@ 2>&1 | sed 's/^/    /';
}


function only_on_release() {
  if [ $(Is_Release) = 0 ]; then
    eval "$@"
  else
      echo "Not running command. Not a release branch"
  fi
}

#
# read any options passed in on the cmd line
#
function get_cmd_opts() {
  while getopts "su:p:e:r:n:l" opt; do
    case $opt in
      u)
        REGISTRY_USERNAME=$OPTARG
        ;;
      p)
        REGISTRY_PASSWORD=${OPTARG}
        ;;
      n)
        CI_USERNAME=${OPTARG}
        ;;
      e)
        CI_EMAIL=${OPTARG}
        ;;
      r)
        REGISTRY_HOST=${OPTARG}
        ;;
      i)
        DOCKER_IMAGE=$OPTARG
        ;;
      s)
        SITE_PUBLISH=true
        ;;
      l)
        DOCKER_LOGIN=true
        ;;
      d)
        DOCKER_TAG_NAME=${OPTARG}
        ;;
      ?)
        echo "Invalid option: -$OPTARG" >&2
        usage
        exit 1
        ;;
      :)
        echo "Option -$OPTARG requires an argument." >&2
        usage
        exit 1
    esac
  done
}

#
# check and set some vars
#
function check_vars_base() {
  REGISTRY_HOST=${REGISTRY_HOST?"is not defined"}
  DOCKER_IMAGE=${DOCKER_IMAGE?"is not defined"}
}

function check_vars_auth() {
  REGISTRY_USERNAME=${REGISTRY_USERNAME?"is not defined"}
  REGISTRY_PASSWORD=${REGISTRY_PASSWORD?"is not defined"}
  CI_EMAIL=${CI_EMAIL?"is not defined"}
}

function check_vars_docker_login() {
  check_vars_base
  check_vars_auth
}

function check_vars_docker_publish() {
  check_vars_docker_login
  VERSION=${VERSION?"is not defined"}
  DOCKER_TAG_NAME=${DOCKER_TAG_NAME?"is not defined"}
}

function check_vars_site_publish() {
  CI_EMAIL=${CI_EMAIL?"is not defined"}
  CI_USERNAME=${CI_USERNAME?"is not defined"}
}

function set_vars() {
  DOCKER_TAG_NAME=${REGISTRY_HOST}/${DOCKER_IMAGE}:${VERSION}
}

#
# show the vars (just important ones, not secret ones) 
#
function dump_vars() {
  cat << EOF
REGISTRY_HOST=${REGISTRY_HOST}
VERSION=${VERSION}
DOCKER_IMAGE=${DOCKER_IMAGE}
DOCKER_TAG_NAME=${DOCKER_TAG_NAME}
EOF

}

#
# We create the ci_vars file for CI builds to use
# and to make it obvious for the build what "vars" are being used
# we dump it out to console (helps with debugging wayard builds)
# This is used like ". ./ci-env-vars.sh"
#
function create_ci_vars() {
  cat << EOF | sed 's/^\s+//g' > ci-env-vars.sh 
     #!/bin/bash
     export REGISTRY_HOST=${REGISTRY_HOST}
     export VERSION=${VERSION}
     export DOCKER_IMAGE=${DOCKER_IMAGE}
     export DOCKER_TAG_NAME=${DOCKER_TAG_NAME}
EOF

  chmod 755 ci-env-vars.sh
  echo "created ci-env-vars.sh"
  echo "----------------------------------------------------"
  cat ci-env-vars.sh
  echo "----------------------------------------------------"
}

#
# Setup some default vars
#
function setup_default_vars() {

  # if the user supplied REGISTRY_HOST, it will be set here (but we check that later)
  if [ "${CI_NAME}" = "travis" ]; then
    REGISTRY_HOST=${REGISTRY_HOST:-commbank-docker-dockerv2-local.artifactoryonline.com}
  fi

}

#----------------------------
# main()
#----------------------------

setup_default_vars

set -o errexit

if [[ -z ${1+x} ]];then 
   echo "Missing the 1st argument 'mode' (setup or publish)" 1>&2 && usage; exit 1;
else 
   MODE=$1
   shift
fi

if [[ ${MODE} != "setup" && ${MODE} != "publish" ]]; then
  echo "Invalid mode ${MODE}" 1>&2
  usage
  exit 1 
fi

get_cmd_opts "$@"

if [[ ${MODE} == "setup" ]]; then
  log "vars-check" check_vars_base
  if [[ "$DOCKER_LOGIN" == "true" ]]; then
    log "vars-check" check_vars_docker_login
    log "docker-login -- ${REGISTRY_USERNAME}@${REGISTRY_HOST}" docker login -u ${REGISTRY_USERNAME} -p ${REGISTRY_PASSWORD} -e ${CI_EMAIL} ${REGISTRY_HOST}
  fi
  log "set_version"
  Version_Write_New
  log "set_vars"
  set_vars
  log "create_ci_vars" create_ci_vars
fi

if [[ ${MODE} == "publish" ]]; then
  log "vars-check" check_vars_docker_publish
  # do we need to login ? 
  if grep --quiet ${REGISTRY_HOST} ${HOME}/.docker/config.json; then
    log "docker-login -- already logged in ${REGISTRY_USERNAME}@${REGISTRY_HOST}" true
  else
    log "docker-login -- ${REGISTRY_USERNAME}@${REGISTRY_HOST}" docker login -u ${REGISTRY_USERNAME} -p ${REGISTRY_PASSWORD} -e ${CI_EMAIL} ${REGISTRY_HOST}
  fi
  log "docker-publish -- docker push ${DOCKER_TAG_NAME}" only_on_release docker push ${DOCKER_TAG_NAME}
  log "docker-remove" docker rmi ${DOCKER_TAG_NAME}
  if [[ "$SITE_PUBLISH" == "true" ]]; then
    log "vars-check-publish" check_vars_site_publish
    if [ -d _site ]; then
      log "add-site-config" 

      echo "dockerTagName: ${DOCKER_TAG_NAME}" >> _site/_config.yml
      echo "dockerImage: ${DOCKER_IMAGE}" >> _site/_config.yml
      echo "dockerImageFull: ${REGISTRY_HOST}/${DOCKER_IMAGE}" >> _site/_config.yml
      echo "registryHost: ${REGISTRY_HOST}" >> _site/_config.yml

      log "_site/config.yml" cat _site/_config.yml

      log "site-publish" $CI_DIR/ci-publish-site.sh _site
    fi
  fi
fi

