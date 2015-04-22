#!/bin/bash

# Every time staging is deployed, we load a baseline data set before running the new code's
# migrations. This script saves a new baseline data set for that purpose.

# This script is called remotely on a push to production. We only want to save a new baseline
# if the code in staging is identical to that in production. To accomplish that, we take the
# production commit SHA as a parameter ($1) and only perform the save if the SHA matches the
# current code checked out.

set -e

cd /home/openfoodweb/apps/openfoodweb/current
if [[ `git rev-parse HEAD` == $1 ]]; then
    mkdir -p db/backup
    pg_dump -h localhost -U openfoodweb openfoodweb_production |gzip > db/backup/staging-baseline.sql.gz
    echo "Staging baseline data saved."
else
    echo "Staging SHA does not match production, we will not save staging baseline data."
fi
