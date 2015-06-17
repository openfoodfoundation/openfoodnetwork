#!/bin/bash

set -ex

# Add production git remote if required
PROD_TEST=`git remote | grep -s 'production' || true`
if [[ "$PROD_TEST" != *production* ]]; then
    git remote add production ubuntu@ofn-prod:apps/openfoodweb/current
fi

echo "--- Saving baseline data for staging"
ssh ofn-staging2 "/home/openfoodweb/apps/openfoodweb/current/script/ci/save_staging_baseline.sh `get_ofn_commit`"

echo "--- Pushing to production"
exec 5>&1
OUTPUT=$(git push production `get_ofn_commit`:master --force 2>&1 |tee /dev/fd/5)
[[ $OUTPUT =~ "Done" ]]
