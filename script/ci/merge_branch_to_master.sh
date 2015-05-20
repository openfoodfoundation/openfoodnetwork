#!/bin/bash

set -ex
source ./script/ci/includes.sh

echo "--- Verifying branch is based on current master"
exit_unless_master_merged

echo "--- Pushing branch"
git push origin $BUILDKITE_COMMIT:master
