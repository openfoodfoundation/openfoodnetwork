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

echo "--- Loading test database"
bundle exec rake db:drop db:create db:schema:load
bundle exec rake parallel:drop parallel:create parallel:load_schema

echo "--- Running tests"
bundle exec rake parallel:spec
