# ci2

[![Build Status](https://travis-ci.org/CommBank/ci2.svg?branch=master)](https://travis-ci.org/CommBank/ci2)
[![Coverage Status](https://coveralls.io/repos/github/CommBank/ci2/badge.svg?branch=master)](https://coveralls.io/github/CommBank/ci2?branch=master)

Scripts used for Continuous Integration

## Overview

ci2 is a "set" of CI helper scripts. To assist with pushing, and publishing versions of code.

To depend on this REPO add the following to your ``.travis.yml`` / ``.drone.yml``

```
curl https://commbank.artifactoryonline.com/commbank/binaries/ci/ci-<VERSION>.tar.gz | tar xz
```

Latest releases can be found here [ci2 releases](https://commbank.artifactoryonline.com/commbank/binaries/ci/)

## Disclaimer

This module is intended to be "pulled" in using curl or wget, as an external dependency. 
This is the only supported approach.

If you don't use a versioned approach for pulling in these scripts, there is no guarantee of your build succeeding, as ci2 may be updated at any time.

## Scripts 

* ``lib-ci`` - Common BASH functions used by all the scripts
* ``artifactory-release.sh`` - release a file (binary, archive, etc) to an artifactory server
* ``bump-docker-version.bsh`` - support script to set a version of Dockerfile, before building.
* ``bump-scala-version.bsh`` - support script to set a versions in scala builds, before building.
* ``bump-scala-version-depend.bsh`` - support script to set a versions in scala builds, before building.
* ``bump-scala-version-val.bsh`` - support script to set a versions in scala builds, before building.
* ``ci-nonrelease.bsh`` - Perform an action, only if the Branch/PR is a NON-Release Branch
* ``ci-release.bsh`` - Perform the action, only if the Branch/PR is a Release Branch
* ``ci-publish-site.bsh`` - Perform the 
* ``dockermake.bsh`` - Build all ``Dockerfile`` images in the Repo 
* ``docker-support.bsh`` - ``setup`` and ``publish`` docker images (implies a build step between each)
* ``gh-commit-comment.bsh`` - uses the GitHub API to create a comment against a specific git commit-sha.
* ``sbt-ci-build-doc.bsh`` - uses sbt to build documentation for the project
* ``sbt-ci-deploy.bsh`` - uses sbt to deploy your artifact
* ``sbt-ci-setup-version.bsh`` - sets up the correct "CI" version for the SBT project
* ``setup-version.bsh`` - Replaces the VERSION file with a common ``ver-date-commish``

## Writing New Scripts

If you find a use case that does not match the above provided list, then please look at 

* existing scripts; and
* the matching ``src/tests/`` folder for examples of how to write tests for your new script

### Testing

The Tests can be executed locally, (i.e. SANS a CI environment).

```
cd src/tests
ENABLE_LOCAL_CI=1 ./test.bsh
```

## Principles

These are some underlying principles for how we do CI and in particular how we design and utilise 
these scripts.

* In build configurations the building and unit testing of the code should not require any CI 
  scripts and be expressed in a similar way that a user would run locally.
* Our standard versioning approach is semantic version plus the build time stamp plus the commish.
* We predominantly utilise our CI scripts to customise the deployment and publication process. This 
  is custom to our environments and there is no expectation that the user will do a publish manually.
* We use CI scripts to set up custom version for builds in a way that is transparent to the build
  tooling. Users provide the semantic version in a way that is suitable for their particular tooling
  and the CI scripts append the time stamp and commish at the beginning of the build.
  e.g. ``(file) VERSION: 2.0.3`` --> ``ci-2.0.3-20160517230553-92fd78d``


