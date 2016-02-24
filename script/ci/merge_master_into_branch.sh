#!/bin/bash

set -e
source ./script/ci/includes.sh

echo "--- Checking if master has already been merged"
set_ofn_commit $BUILDKITE_COMMIT
succeed_if_master_merged

echo "--- Merging master into this branch"
git checkout $BUILDKITE_BRANCH
git merge origin/$BUILDKITE_BRANCH
git merge origin/master -m "Auto-merge from CI [skip ci]"
git push origin $BUILDKITE_BRANCH
git checkout origin/$BUILDKITE_BRANCH

set_ofn_commit `git rev-parse $BUILDKITE_BRANCH`
