#!/bin/bash
#
# Install our selected Ruby version defined in the .ruby-version file.
#
# Requires and tries to install if missing:
# - [rbenv](https://github.com/rbenv/rbenv#readme)
# - [ruby-build](https://github.com/rbenv/ruby-build#readme)
#
# If our ruby-build version is outdated and it can't build the version we want
# then we try upgrading ruby-build and installing again.

if ! command -v rbenv > /dev/null; then
  # Install rbenv:
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  ~/.rbenv/bin/rbenv init
  eval "$(~/.rbenv/bin/rbenv init -)"

  # Install ruby-build:
  mkdir -p "$(rbenv root)"/plugins
  git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
fi

if rbenv install --skip-existing; then
  echo "Ruby is installed."
else
  echo "Upgrading rbenv's ruby-build:"
  git -C "$(rbenv root)"/plugins/ruby-build pull

  rbenv install
fi
