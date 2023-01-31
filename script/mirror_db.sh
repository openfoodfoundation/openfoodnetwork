#!/bin/bash

# Used to pull data from production or staging servers into local dev database
# Useful for when you want to test a migration against production data, or see
# the effect of codebase changes on real-life data

set -e

HOST="$1"
BUCKET="$2"
: ${DB_USER='ofn_user'}
: ${DB_DATABASE='openfoodnetwork'}
: ${DB_CACHE_FILE="tmp/$HOST.sql"}

DB_OPTIONS=(
--exclude-table-data=sessions
--exclude-table-data=spree_log_entries
--exclude-table-data=spree_state_changes
--no-acl
)

if [ -z "$HOST" ]; then
  echo "[Error] SSH host missing.
Usage: $0 openfoodnetwork@openfoodnetwork.org.au" >&2
  exit 1
fi

RAILS_RUN='bundle exec rails runner'

# -- Mirror database
echo "Mirroring database..."
dropdb -h localhost -U ofn open_food_network_dev --if-exists
createdb -h localhost -U ofn open_food_network_dev

if [ -s "$DB_CACHE_FILE" ]; then
  echo "Using cached dump '$DB_CACHE_FILE'."
  psql -h localhost -U ofn open_food_network_dev < "$DB_CACHE_FILE"
else
  echo "Downloading dump to '$DB_CACHE_FILE'."
  ssh -C "$HOST" "pg_dump -h localhost -U $DB_USER $DB_DATABASE ${DB_OPTIONS[@]}"\
  | tee "$DB_CACHE_FILE"\
  | psql -h localhost -U ofn open_food_network_dev
fi

# -- Disable S3
echo "Preparing mirrored database..."
$RAILS_RUN script/prepare_imported_db.rb

# -- Mirror images
if [ -n "$BUCKET" ]; then
  if hash aws 2>/dev/null; then
    echo "Mirroring images..."
    aws s3 sync "s3://$BUCKET/public" public/
  else
    echo "Please install the AWS CLI tools so that I can copy the images from $BUCKET for you."
    echo "eg. sudo easy_install awscli"
  fi
fi
