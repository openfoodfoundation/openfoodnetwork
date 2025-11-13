#!/bin/bash

#
# Runs linters and pipes their output to reviewdog so it annotates a pull request with the issues found
#

set -o pipefail

echo "::group:: Running prettier with reviewdog 🐶 ..."

"$(npm root)/.bin/prettier" --check . 2>&1 | sed --regexp-extended 's/(\[warn\].*)$/\1 File is not properly formatted./' \
  | reviewdog \
      -efm="%-G[warn] Code style issues found in %s. Run Prettier to fix. File is not properly formatted." \
      -efm="[%tarn] %f %m" \
      -efm="%E[%trror] %f: %m (%l:%c)" \
      -efm="%C[error]%r" \
      -efm="%Z[error]%r" \
      -efm="%-G%r" \
      -name="prettier" \
      -reporter="github-pr-annotations" \
      -filter-mode="nofilter" \
      -fail-level="any" \
      -level="error" \
      -tee

prettier=$?

echo "::group:: Running rubocop with reviewdog 🐶 ..."

bundle exec rubocop \
  --fail-level info \
  | reviewdog -f="rubocop" \
      -name="rubocop" \
      -reporter="github-pr-annotations" \
      -filter-mode="nofilter" \
      -level="error" \
      -fail-level="any" \
      -tee

rubocop=$?

echo "::group:: Running haml-lint with reviewdog 🐶 ..."

bundle exec haml-lint \
  --fail-level warning \
  | reviewdog -f="haml-lint" \
      -name="haml-lint" \
      -reporter="github-pr-annotations" \
      -filter-mode="nofilter" \
      -level="error" \
      -fail-level="any" \
      -tee

haml_lint=$?

! (( prettier || rubocop || haml_lint ))
