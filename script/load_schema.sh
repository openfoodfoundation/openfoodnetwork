#!/bin/bash
set -e

echo "🔍 Checking if schema is missing or outdated..."

# Get the current DB version
DB_VERSION=$(bundle exec rails db:version | grep 'Current version' | awk '{print $NF}')
FILE_VERSION=$(grep 'version:' db/schema.rb | awk '{print $2}')

if [ -z "$DB_VERSION" ] || [ "$DB_VERSION" != "$FILE_VERSION" ]; then
  echo "🧾 Schema mismatch detected (DB=$DB_VERSION, File=$FILE_VERSION). Running db:schema:load..."
  bundle exec rails db:schema:load
else
  echo "✅ Schema is up to date (version $DB_VERSION)."
fi

####################