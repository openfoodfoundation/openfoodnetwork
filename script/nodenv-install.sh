#!/bin/bash
#
# Install our selected Node version defined in the .node-version file.
#
# If our node-build version is outdated and it can't build the version we want
# then we try upgrading node-build and installing again.

# Fail if a single command fails.
set -e

if ! command -v nodenv > /dev/null; then
  printf "Please install https://github.com/nodenv/nodenv.\n"
  printf '```'"\n"
  printf "git clone https://github.com/nodenv/nodenv.git ~/.nodenv\n"
  printf "git clone https://github.com/nodenv/node-build.git ~/.nodenv/plugins/node-build\n"
  printf "nodenv init\n"
  printf 'eval "$(nodenv init -)"'"\n"
  printf '```'"\n"
  exit 1
fi

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
