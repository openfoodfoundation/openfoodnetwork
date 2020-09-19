#!/bin/bash

# This script runs the model tests and RuboCop.

echo '--------------------------------------------------------------'
echo 'BEGIN: docker-compose run web bundle exec rake db:test:prepare'
echo '--------------------------------------------------------------'
docker-compose run web bundle exec rake db:test:prepare
echo '------------------------------------------------------------'
echo 'END: docker-compose run web bundle exec rake db:test:prepare'
echo '------------------------------------------------------------'

echo '-----------------------------------------------------'
echo 'BEGIN: docker-compose run web bundle exec spec/models'
echo '-----------------------------------------------------'
docker-compose run web bundle exec rspec spec/models
echo '---------------------------------------------------------'
echo 'END: docker-compose run web bundle exec rspec spec/models'
echo '---------------------------------------------------------'

bash cop.sh
