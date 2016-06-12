#!/bin/bash

export TEST_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [[ ! -d "$TEST_PATH" ]]; then TEST_PATH="$PWD"; fi
export MAIN_PATH=${TEST_PATH}/../../main/bash

. ${MAIN_PATH}/lib-ci

function init() {
  # Always show the CI env
  echo ":: [$0] Dumping CI environment..."
  CI_Env_Dump
  echo ":: [$0] TEST_PATH=${TEST_PATH}"
  echo ":: [$0] MAIN_PATH=${MAIN_PATH}"
}

function cleanup() {
  # 
  # all tests create .tmp-blah directories
  # we remote them here for purity
  #
  echo ":: [$0] cleanup temp dirs"
  find . -name '_tmp-*' | xargs -L1 -Ixx sh -c 'echo "rm -rf xx"  && rm -rf xx'
}

function run_tests() {
  cd ${TEST_PATH}
  # Run the tests
  for i in $(find . -mindepth 1 -name 'test-*' -type f -print | sort); do
      echo ":: [$0] $i"
      bash $i
      if [ $? != 0 ]; then
          echo ":: [$0] previous test [$i] failed - not continuing"
          cleanup
          exit 1
      fi
  done
  echo ":: [$0] All tests completed successfully."
}

#
# main()
#
init
run_tests
cleanup


