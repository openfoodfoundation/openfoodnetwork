#!/bin/bash

set -e

ST2_TEST=`git remote | grep -s 'staging2' || true`
if [[ "$ST2_TEST" != *staging2* ]]; then
    git remote add staging2 openfoodweb@ofn-staging2:apps/openfoodweb/current
fi

[[ $(git push staging2 $BUILDKITE_COMMIT:master --force 2>&1) =~ "Done" ]]
