#!/bin/bash

# This script runs the controller tests and RuboCop.

echo '--------------------------------------------------------------'
echo 'BEGIN: docker-compose run web bundle exec rake db:test:prepare'
echo '--------------------------------------------------------------'
docker-compose run web bundle exec rake db:test:prepare
echo '------------------------------------------------------------'
echo 'END: docker-compose run web bundle exec rake db:test:prepare'
echo '------------------------------------------------------------'

echo '----------------------------------------------------------'
echo 'BEGIN: docker-compose run web bundle exec spec/controllers'
echo '----------------------------------------------------------'
docker-compose run web bundle exec rspec spec/controllers
echo '--------------------------------------------------------------'
echo 'END: docker-compose run web bundle exec rspec spec/controllers'
echo '--------------------------------------------------------------'

bash cop.sh
