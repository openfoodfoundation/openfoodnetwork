#!/bin/bash

set -e
source ./script/ci/includes.sh

succeed_if_master_merged

git checkout $BUILDKITE_BRANCH
git merge origin/$BUILDKITE_BRANCH
git merge origin/master -m "Auto-merge from CI [skip ci]"
git push origin $BUILDKITE_BRANCH
git checkout origin/$BUILDKITE_BRANCH
