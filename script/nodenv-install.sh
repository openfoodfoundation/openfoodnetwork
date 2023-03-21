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

  if command -v brew &> /dev/null; then
    # Installation via Homebrew is recommended on macOS.
    brew upgrade node-build
  else
    git -C "$(nodenv root)"/plugins/node-build pull
  fi

  nodenv install
fi
