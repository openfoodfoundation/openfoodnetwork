#! /bin/sh
#
# A server's disk fills up with outdated packages over time.
# You can call this script to gain space back when you need it.
# Feel free to add commands that free up significant space.

set -ex

# This assumes that this is the only app using this bundle:
bundle clean --force

rbenv versions
# TODO: delete old rubies on the server.
# Can we guard against deleting rubies in dev?

yarn cache clean

nodenv versions | grep  '^  [0-9.]\+$' | while read v
  do nodenv uninstall --force "$v"
done
