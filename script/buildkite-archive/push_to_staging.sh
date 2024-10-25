#!/bin/bash

set -e
source "`dirname $0`/includes.sh"

OFN_COMMIT=$(get_ofn_commit)
if [ "$OFN_COMMIT" = 'OFN_COMMIT_NOT_FOUND' ]; then
  OFN_COMMIT=$(git rev-parse $BUILDKITE_COMMIT)
fi
STAGING_REMOTE="${STAGING_REMOTE:-$STAGING_SSH_HOST:$STAGING_CURRENT_PATH}"

echo "--- Checking environment variables"
require_env_vars OFN_COMMIT STAGING_SSH_HOST STAGING_CURRENT_PATH STAGING_REMOTE STAGING_SERVICE STAGING_DB_HOST STAGING_DB_USER STAGING_DB

if [ "$REQUIRE_MASTER_MERGED" = false ]; then
  echo "--- NOT verifying branch is based on current master"
else
  echo "--- Verifying branch is based on current master"
  exit_unless_master_merged
fi

# TODO: Optimise staging deployment
# This is stopping and re-starting unicorn and delayed job.
echo "--- Loading baseline data"
VARS="CURRENT_PATH='$STAGING_CURRENT_PATH' SERVICE='$STAGING_SERVICE' DB_HOST='$STAGING_DB_HOST' DB_USER='$STAGING_DB_USER' DB='$STAGING_DB'"
ssh "$STAGING_SSH_HOST" "$VARS $STAGING_CURRENT_PATH/script/ci/load_staging_baseline.sh"

# This is stopping and re-starting unicorn and delayed job again.
echo "--- Pushing to staging"
exec 5>&1
OUTPUT=$(git push "$STAGING_REMOTE" "$OFN_COMMIT":master --force 2>&1 |tee /dev/fd/5)
[[ $OUTPUT =~ "Done" ]]
