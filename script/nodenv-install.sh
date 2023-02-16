#!/bin/bash
#
# Install our selected Node version defined in the .node-version file.
#
# If our node-build version is outdated and it can't build the version we want
# then we try upgrading node-build and installing again.

if nodenv install --skip-existing; then
  echo "Correct Node version is installed."
else
  echo "Upgrading node-build:"
  # If homebrew (macOS) installed, try that first. Otherwise look in plugins directory.
  brew upgrade node-build || git -C "$(nodenv root)"/plugins/node-build pull

  nodenv install
fi
