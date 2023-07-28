#!/bin/bash
#
# Fixes safe cops automatically and creates a commit for each.
#
# Usage:
#     ./script/rubocop-autocorrect.sh [-n 7]
#
# The optional parameter is passed to `head` to limit the number of iterations.
# Use `-n -0` to remove the limit.

if git add --dry-run --all | grep --quiet .; then
  echo "Dirty working tree. Please start on a fresh branch."
  exit 1
fi

# Refresh todo file so that following commits include only related changes:
bundle exec rubocop --regenerate-todo --no-auto-gen-timestamp
git commit --all --message "Regenerate Rubocop's TODO file"

# Iterate over all safe cops.
# Looking at the 5 lines following the autocorrection comment works for our
# current todo file. If cops start to add more comment lines in the future then
# this may break and not find those cops.
# Alternatives include using `sed` for parsing or running rubocop in fail-fast
# mode to find the next failing cop.
grep "This cop supports safe autocorrection" -A 5 .rubocop_todo.yml\
  | grep '^[A-Z]'\
  | head "${@:1}"\
  | tr -d :\
  | while read cop; do
      echo "Trying to autocorrect safely: $cop"
      bundle exec rubocop --regenerate-todo --except "$cop"

      echo "Safely autocorrect $cop" > .git/COMMIT_EDITMSG
      echo "" >> .git/COMMIT_EDITMSG
      bundle exec rubocop --autocorrect >> .git/COMMIT_EDITMSG
      if grep -q "offenses corrected" .git/COMMIT_EDITMSG; then
        git add --all
        git commit --file .git/COMMIT_EDITMSG
      else
        echo "No corrections made for $cop. Skipping."
      fi

    done
