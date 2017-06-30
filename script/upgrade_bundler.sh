#!/bin/sh

# This shell script looks for the last used Bundler version in Gemfile.lock and
# installs exactly that version, removing other versions.

# Fail if a single command fails.
set -e

# `grep -m 1`: find the first occurrence of "BUNDLED WITH"
# `-A`:        print the next line after "BUNDLED WITH" as well
# `-x -F`:     find exactly that string without interpreting regex
# `tail -n 1`: take the last line, the version line
# `tr -d`:     delete all spaces, the indent before the version
version="$(grep -m 1 -A 1 -x -F "BUNDLED WITH" Gemfile.lock | tail -n 1  | tr -d '[:space:]')"

if [ -z "$version" ]; then
  echo "No bundler version in Gemfile.lock."
  exit 1
fi

current="$(bundler --version)"

if [ "$current" = "Bundler version $version" ]; then
  echo "Already up-to-date: $current"
  exit 0
fi

gem install bundler -v "$version"
gem cleanup bundler
