#!/bin/bash

set -e
source "`dirname $0`/includes.sh"

OFN_COMMIT=$(get_ofn_commit)
if [ "$OFN_COMMIT" = 'OFN_COMMIT_NOT_FOUND' ]; then
  OFN_COMMIT=$(git rev-parse $BUILDKITE_COMMIT)
fi

GITHUB_REPO="$(echo $BUILDKITE_REPO | sed 's/git@github.com:\(.*\).git/\1/')"
GITHUB_API_URL="https://api.github.com/repos/$GITHUB_REPO/commits/$OFN_COMMIT/status"

echo "--- Checking environment variables"
require_env_vars OFN_COMMIT BUILDKITE_REPO

echo "--- Checking GitHub status"
if [ -n "$1" ]; then
  REQUIRED_STATUS="$1"
else
  REQUIRED_STATUS="success"
fi
echo "Require status '$REQUIRED_STATUS'"
echo "Visiting $GITHUB_API_URL"
curl -s "$GITHUB_API_URL" | head -n 2 | grep '^ *"state":' | egrep "\"$REQUIRED_STATUS\",\$"
