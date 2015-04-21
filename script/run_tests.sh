#!/bin/bash

set -e

echo "--- Loading environment"
source /var/lib/jenkins/.rvm/environments/ruby-1.9.3-p392
if [ ! -f config/application.yml ]; then
    ln -s application.yml.example config/application.yml
fi

echo "--- Bundling"
bundle install

echo "--- Loading test database"
bundle exec rake db:test:load

echo "--- Running tests"
bundle exec rspec spec --format progress
