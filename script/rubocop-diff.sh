#!/bin/bash
#
# While you are developing, you can call this script to check all
# changed files. And then you can also tell Git to check before every
# commit by adding this line to your `.git/hooks/pre-commit` file:
#
#   ./script/rubocop-diff.sh --cached || exit 1
#

rubocop="`dirname $0`/../bin/rubocop"
cached="$1" # may be empty

if git diff $cached --diff-filter=ACMR HEAD --quiet; then
	# nothing changed
	exit 0
fi

exec git diff $cached --name-only --relative --diff-filter=ACMR HEAD |\
	xargs \
	$rubocop --force-exclusion \
                 --fail-level A \
                 --format simple \
                 --parallel --cache true
