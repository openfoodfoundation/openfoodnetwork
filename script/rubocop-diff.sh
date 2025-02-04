#!/bin/bash
#
# While you are developing, you can call this script to check all
# changed files. You can auto-correct them if you wish:
#
#   ./script/rubocop-diff.sh -a
#
# And then you can also tell Git to check before every
# commit by adding this line to your `.git/hooks/pre-commit` file:
#
#   ./script/rubocop-diff.sh --cached || exit 1
#

# If you prefer to use faster boot times of the Rubocop Server then you can
# define your way of calling rubocop:
#
#   export RUBOCOP_BIN="rubocop --server"
#
# Or locked to the bundled version (needs update after `bundle update`):
#
#   export RUBOCOP_BIN="`bundle show rubocop`/exe/rubocop --server"
#
# I don't know how to set that automatically though.
#
# But I observed some performance improvement:
#
# * Using default binstup with spring: boot: 6.2s, repeat: 0.4s, 0.4s, ...
# * Using rubocop server binstub without bundler: boot: 2s, repeat: 1s, 0.3s, ...
# * Using rubocop executable directly: boot: 2.1s, repeat: 1s, 0.16s, ...
#
# The default binstub is still the safest, always using the bundled version.
: ${RUBOCOP_BIN="`dirname $0`/../bin/rubocop"}

if [ "$1" = "--cached" ]; then
  cached="$1"
else
  rubocop_opt="$1"
fi

if git diff $cached --diff-filter=ACMR HEAD --quiet; then
	# nothing changed
	exit 0
fi

exec git diff $cached --name-only --relative --diff-filter=ACMR HEAD |\
	xargs \
	$RUBOCOP_BIN \
          --force-exclusion \
          --fail-level A \
          --format simple \
          --parallel --cache true \
	  "$rubocop_opt"
