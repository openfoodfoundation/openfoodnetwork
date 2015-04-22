#!/bin/bash

set -e

# Add staging git remote if required
ST2_TEST=`git remote | grep -s 'staging2' || true`
if [[ "$ST2_TEST" != *staging2* ]]; then
    git remote add staging2 openfoodweb@ofn-staging2:apps/openfoodweb/current
fi

echo "--- Loading baseline data"
ssh ofn-staging2 "/home/openfoodweb/apps/openfoodweb/current/script/load_staging_baseline.sh"

echo "--- Pushing to staging"
[[ $(git push staging2 $BUILDKITE_COMMIT:master --force 2>&1) =~ "Done" ]]
