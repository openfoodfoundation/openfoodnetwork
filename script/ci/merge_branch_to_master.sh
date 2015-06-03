#!/bin/bash

set -ex
source ./script/ci/includes.sh

echo "--- Verifying branch is based on current master"
exit_unless_master_merged

echo "--- Merging and pushing branch"
git checkout master
git merge origin/master
git merge origin/$BUILDKITE_BRANCH
git push origin master
git checkout origin/$BUILDKITE_BRANCH
