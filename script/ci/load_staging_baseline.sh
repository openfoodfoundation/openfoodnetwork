#!/bin/bash

# Every time staging is deployed, we load a baseline data set before running the new code's
# migrations. This script loads the baseline data set, after first taking a backup of the
# current database.

set -e
source "`dirname $0`/includes.sh"

# We need ruby to call script/delayed_job
export PATH="$HOME/.rbenv/shims:$PATH"

echo "Checking environment variables"
require_env_vars CURRENT_PATH SERVICE DB_HOST DB_USER DB

cd "$CURRENT_PATH"

echo "Stopping unicorn and delayed job..."
service "$SERVICE" stop
RAILS_ENV=staging script/delayed_job -i 0 stop

echo "Backing up current data..."
mkdir -p db/backup
pg_dump -h "$DB_HOST" -U "$DB_USER" "$DB" |gzip > db/backup/staging-`date +%Y%m%d%H%M%S`.sql.gz

echo "Loading baseline data..."
drop_and_recreate_database "$DB" -U "$DB_USER"
gunzip -c db/backup/staging-baseline.sql.gz |psql -h "$DB_HOST" -U "$DB_USER" "$DB"

echo "Restarting unicorn..."
service "$SERVICE" start
# Delayed job is restarted by monit

echo "Done!"
