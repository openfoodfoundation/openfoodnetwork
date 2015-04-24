#!/bin/bash

# Every time staging is deployed, we load a baseline data set before running the new code's
# migrations. This script loads the baseline data set, after first taking a backup of the
# current database.

set -e
source ./script/ci/includes.sh

cd /home/openfoodweb/apps/openfoodweb/current

echo "Stopping unicorn and delayed job..."
service unicorn_openfoodweb stop
RAILS_ENV=staging script/delayed_job -i 0 stop

echo "Backing up current data..."
mkdir -p db/backup
pg_dump -h localhost -U openfoodweb openfoodweb_production |gzip > db/backup/staging-`date +%Y%m%d%H%M%S`.sql.gz

echo "Loading baseline data..."
drop_and_recreate_database "openfoodweb_production"
gunzip -c db/backup/staging-baseline.sql.gz |psql -h localhost -U openfoodweb openfoodweb_production

echo "Restarting unicorn..."
service unicorn_openfoodweb start
# Delayed job is restarted by monit

echo "Done!"
