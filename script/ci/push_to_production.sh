#!/bin/bash

set -e
source "`dirname $0`/includes.sh"

OFN_COMMIT=$(get_ofn_commit)
if [ "$OFN_COMMIT" = 'OFN_COMMIT_NOT_FOUND' ]; then
  OFN_COMMIT=$(git rev-parse $BUILDKITE_COMMIT)
fi

echo "--- Checking environment variables"
require_env_vars OFN_COMMIT STAGING_SSH_HOST STAGING_CURRENT_PATH STAGING_SERVICE STAGING_DB_HOST STAGING_DB_USER STAGING_DB PRODUCTION_REMOTE

echo "--- Saving baseline data for staging"
VARS="CURRENT_PATH='$STAGING_CURRENT_PATH' SERVICE='$STAGING_SERVICE' DB_HOST='$STAGING_DB_HOST' DB_USER='$STAGING_DB_USER' DB='$STAGING_DB'"
ssh "$STAGING_SSH_HOST" "$VARS $STAGING_CURRENT_PATH/script/ci/save_staging_baseline.sh $OFN_COMMIT"

echo "--- Pushing to production"
exec 5>&1
OUTPUT=$(git push "$PRODUCTION_REMOTE" "$OFN_COMMIT":master --force 2>&1 |tee /dev/fd/5)
[[ $OUTPUT =~ "Done" ]]
