#!/bin/bash

# Used to pull data from production or staging servers into local dev database
# Useful for when you want to test a migration against production data, or see
# the effect of codebase changes on real-life data

# Usage: script/mirror_db.sh [ofn-staging1|ofn-staging2|ofn-prod]

set -e

if hash zeus 2>/dev/null && [ -e .zeus.sock ]; then
  RAILS_RUN='zeus r'
else
  RAILS_RUN='bundle exec rails runner'
fi

if [[ $1 != 'ofn-no' ]]; then
  DB_USER='openfoodweb'
  DB_DATABASE='openfoodweb_production'
else
  DB_USER='ofn_user'
  DB_DATABASE='openfoodnetwork'
fi

DB_OPTIONS='--exclude-table-data=sessions'

# -- Mirror database
echo "Mirroring database..."
echo "drop database open_food_network_dev" | psql -h localhost -U ofn open_food_network_test
echo "create database open_food_network_dev" | psql -h localhost -U ofn open_food_network_test
ssh $1 "pg_dump -h localhost -U $DB_USER $DB_DATABASE $DB_OPTIONS |gzip" |gunzip |psql -h localhost -U ofn open_food_network_dev


# -- Disable S3
echo "Preparing mirrored database..."
$RAILS_RUN script/prepare_imported_db.rb


# -- Mirror images
if hash aws 2>/dev/null; then
    echo "Mirroring images..."
    BUCKET=`echo $1 | sed s/-/_/ | sed "s/\\([0-9]\\)/_\1/" | sed s/prod/production/`
    aws s3 sync s3://$BUCKET/public public/

else
    echo "Please install the AWS CLI tools so that I can copy the images from $1 for you."
    echo "eg. sudo easy_install awscli"
fi
