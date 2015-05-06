#!/bin/bash

set -e

# Add production git remote if required
PROD_TEST=`git remote | grep -s 'production' || true`
if [[ "$PROD_TEST" != *production* ]]; then
    git remote add production ubuntu@ofn-prod:apps/openfoodweb/current
fi

echo "--- Saving baseline data for staging"
ssh ofn-staging2 "/home/openfoodweb/apps/openfoodweb/current/script/ci/save_staging_baseline.sh $BUILDKITE_COMMIT"

echo "--- Pushing to production"
output=$(git push production $BUILDKITE_COMMIT:master --force 2>&1)
echo $output
[[ $output =~ "Done" ]]
