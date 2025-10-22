#!/bin/bash

#
# Runs prettier and pipes its output to reviewdog so it annotates a pull request with the issues found
#

"$(npm root)/.bin/prettier" --check . 2>&1 | sed --regexp-extended 's/(\[warn\].*)$/\1 File is not properly formatted./'

"$(npm root)/.bin/prettier" --check . 2>&1 | sed --regexp-extended 's/(\[warn\].*)$/\1 File is not properly formatted./' \
  | reviewdog \
      -efm="%-G[warn] Code style issues found in the above file(s). Forgot to run Prettier%. File is not properly formatted." \
      -efm="[%tarn] %f %m" \
      -efm="%E[%trror] %f: %m (%l:%c)" \
      -efm="%C[error]%r" \
      -efm="%Z[error]%r" \
      -efm="%-G%r" \
      -name="prettier" \
      -reporter="github-pr-check" \
      -filter-mode="added" \
      -fail-level="error" \
      -level="error" \
      -tee
