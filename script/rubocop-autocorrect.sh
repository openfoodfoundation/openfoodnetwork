#!/bin/sh
#
# Fixes safe cops automatically and creates a commit for each.
#

if git add --dry-run --all | grep --quiet .; then
  echo "Dirty working tree. Please start on a fresh branch."
  exit 1
fi

# Refresh todo file so that following commits include only related changes:
bundle exec rubocop --regenerate-todo
git commit --all --message "Regenerate Rubocop's TODO file"

# Iterate over all safe cops:
grep "This cop supports safe autocorrection" -A 5 .rubocop_todo.yml\
  | grep '^[A-Z]'\
  | tr -d :\
  | while read cop; do
      echo "Trying to autocorrect safely: $cop"
      bundle exec rubocop --regenerate-todo --except "$cop"

      echo "Safely autocorrect $cop\n" > .git/COMMIT_EDITMSG
      bundle exec rubocop --autocorrect >> .git/COMMIT_EDITMSG
      git add --all
      git commit --file .git/COMMIT_EDITMSG
    done
