#!/bin/bash

set -e

echo "--- Loading environment"
source ./script/ci/includes.sh
load_environment
checkout_ofn_commit

echo "--- Verifying branch is based on current master"
exit_unless_master_merged

echo "--- Bundling"
bundle install

echo "--- Running tests"
./script/karma run
