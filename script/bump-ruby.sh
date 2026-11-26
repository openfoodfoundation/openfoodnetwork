#!/usr/bin/env sh

if [ "$#" -lt 1 ]; then
  echo "Usage:   $0 <new-version>"
  echo "Example: $0 3.4.8"
  exit 1
fi

set -ex

OLD_VERSION=$(cat .ruby-version)
NEW_VERSION=$1

# Replace the old version with the new version.
#\Q...\E ensures any special characters (dots) are treated as literals.
perl -pi -e "s/\Q$OLD_VERSION\E/$NEW_VERSION/g" .ruby-version Dockerfile

script/rbenv-install.sh

# Update bundler to the version shipped with Ruby:
bundle update --bundler

git commit -a -m "Bump Ruby from $OLD_VERSION to $NEW_VERSION"
