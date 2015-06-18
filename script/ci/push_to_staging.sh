#!/bin/bash

set -e
source ./script/ci/includes.sh

# Add staging git remote if required
ST2_TEST=`git remote | grep -s 'staging2' || true`
if [[ "$ST2_TEST" != *staging2* ]]; then
    git remote add staging2 openfoodweb@ofn-staging2:apps/openfoodweb/current
fi

echo "--- Verifying branch is based on current master"
exit_unless_master_merged

echo "--- Loading baseline data"
ssh ofn-staging2 "/home/openfoodweb/apps/openfoodweb/current/script/ci/load_staging_baseline.sh"

echo "--- Pushing to staging"
exec 5>&1
OUTPUT=$(git push staging2 `get_ofn_commit`:master --force 2>&1 |tee /dev/fd/5)
[[ $OUTPUT =~ "Done" ]]
