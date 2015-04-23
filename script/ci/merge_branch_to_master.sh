#!/bin/bash

set -e
source ./script/ci/includes.sh

echo "--- Verifying branch is based on current master"
exit_unless_master_merged

echo "--- Pushing branch"
echo git push origin $BUILDKITE_COMMIT:master
