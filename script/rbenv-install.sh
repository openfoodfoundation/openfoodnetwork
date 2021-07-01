#!/bin/bash
#
# Install our selected Ruby version defined in the .ruby-version file.
#
# If our ruby-build version is outdated and it can't build the version we want
# then we try upgrading ruby-build and installing again.

if rbenv install --skip-existing; then
  echo "Ruby is installed."
else
  echo "Upgrading rbenv's ruby-build:"
  git -C "$(rbenv root)"/plugins/ruby-build pull

  rbenv install
fi
