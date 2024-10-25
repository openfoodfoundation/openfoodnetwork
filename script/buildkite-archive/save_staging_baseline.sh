#!/bin/bash

# Every time staging is deployed, we load a baseline data set before running the new code's
# migrations. This script saves a new baseline data set for that purpose.

# This script is called remotely on a push to production. We only want to save a new baseline
# if the code in staging is identical to that in production. To accomplish that, we take the
# production commit SHA as a parameter ($1) and only perform the save if the SHA matches the
# current code checked out.

set -e
source "`dirname $0`/includes.sh"

echo "Checking environment variables"
require_env_vars CURRENT_PATH SERVICE DB_HOST DB_USER DB

cd "$CURRENT_PATH"
if [[ `git rev-parse HEAD` == $1 ]]; then
    mkdir -p db/backup
    pg_dump -h "$DB_HOST" -U "$DB_USER" "$DB" |gzip > db/backup/staging-baseline.sql.gz
    echo "Staging baseline data saved."
else
    echo "Staging SHA does not match production, we will not save staging baseline data."
    echo "'`git rev-parse HEAD`' is not '$1'"
fi
