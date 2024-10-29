#!/bin/bash

# Save baseline data for staging which can be restored in case a pull request
# messes with the database.

set -e

# Load default values if not already set.
: ${DB_USER='ofn_user'}
: ${DB_DATABASE='openfoodnetwork'}

dstdir="$HOME/apps/openfoodnetwork/shared"
dstfile="$dstdir/staging-baseline.sql.gz"

mkdir -p "$dstdir"
pg_dump -h localhost -U "$DB_USER" "$DB_DATABASE" | gzip > "$dstfile"
echo "Staging baseline data saved."
