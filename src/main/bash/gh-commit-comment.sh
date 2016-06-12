#!/bin/sh

set -e

# this scripts uses the GitHub API to create a comment against a specific
# git commit-sha.
#
# our specific use case is to have our CI system post comments against a commit
# which is part of a pull request.
#
# example call:
#   ./gh-commit-comment.sh -e http://code.br.zbi.cba/api/v3 -u zbi-ci -p xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx -r ZBI/zbi-infra-dev -s ad9e0fadf1658ecf0fac0068c4e923ee26e73bc3 -f gh-comment.json
#
# please see the comments below for details on each command line flag
#
# NOTE: on failure it returns a non-zero exit code so that our CI process
# registers the error
#
# see the page below for the API details:
# - https://developer.github.com/v3/repos/comments/#create-a-commit-comment

usage() { echo "Usage: $0 [-e <GH or GHE endpoint>] [-u <API user>] [-p <API personal token>] [-r <repository>] [-s <commit-sha>] [-f <JSON comments file>]" 1>&2; }

while getopts ":e:u:p:r:s:f:" o; do
    case "${o}" in
        e)
            # GitHub or GHE endpoint E.g. https://api.github.com
            e=${OPTARG}
            ;;
        u)
            # GitHub or GHE API user
            u=${OPTARG}
            ;;
        p)
            # GitHub or GHE API user personal token
            p=${OPTARG}
            ;;
        r)
            # repository is in the form of username/repo E.g. CommBank/zbi
            r=${OPTARG}
            ;;
        s)
            # Git commit-sha to comment against
            s=${OPTARG}
            ;;
        f)
            # file with JSON payload to submit
            # e.g. the file gh-comment.json with content as follows
            # {"body":"Your comment here"}
            f=${OPTARG}
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${e}" ] || [ -z "${u}" ] || [ -z "${p}" ] || [ -z "${r}" ] || [ -z "${s}" ] || [ -z "${f}" ]; then
    usage
    exit 1
fi

curl \
  --fail \
  -u $u:$p \
  -H "Content-Type: application/json" \
  -X POST --data @$f \
  $e/repos/$r/commits/$s/comments
