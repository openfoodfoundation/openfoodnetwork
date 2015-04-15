#!/bin/bash

set -e

echo "--- Bundling"
bundle install

echo "--- Preparing test database"
bundle exec rake db:test:prepare

echo "--- Running tests"
bundle exec rake
