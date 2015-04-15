#!/bin/bash

set -e

echo "--- Loading environment"
source /var/lib/jenkins/.rvm/environments/ruby-1.9.3-p392

echo "--- Bundling"
bundle install

echo "--- Preparing test database"
bundle exec rake db:test:prepare

echo "--- Running tests"
bundle exec rake
