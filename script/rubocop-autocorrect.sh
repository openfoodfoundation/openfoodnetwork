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

# Iterate over all safe cops:
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
      git add --all
      git commit --file .git/COMMIT_EDITMSG
    done
