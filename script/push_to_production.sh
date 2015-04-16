#!/bin/bash

set -e

PROD_TEST=`git remote | grep -s 'production' || true`
if [[ "$PROD_TEST" != *production* ]]; then
    git remote add production ubuntu@ofn-prod:apps/openfoodweb/current
fi

[[ $(git push production $BUILDKITE_COMMIT:master --force 2>&1) =~ "Done" ]]
