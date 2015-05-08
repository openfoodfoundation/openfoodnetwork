#!/bin/bash

set -e

echo "--- Loading environment"
source ./script/ci/includes.sh
load_environment

echo "--- Verifying branch is based on current master"
exit_unless_master_merged

echo "--- Bundling"
bundle install

echo "--- Loading test database"
bundle exec rake db:test:load

echo "--- Running tests"
bundle exec rspec spec
