#!/bin/bash

# Restore baseline data for staging in case a pull request messed with
# the database.

set -e

: ${DB_USER='ofn_user'}
: ${DB_DATABASE='openfoodnetwork'}

srcdir="$HOME/apps/openfoodnetwork/shared"
srcfile="$srcdir/staging-baseline.sql.gz"

if [ -f "$srcfile" ]; then
	echo "Restoring data from: $srcfile"
else
	>&2 echo "[Error] No baseline data available at: $srcfile"
	exit 1
fi

dropdb -h localhost -U "$DB_USER" "$DB_DATABASE" --if-exists
createdb -h localhost -U "$DB_USER" "$DB_DATABASE"

gunzip -c "$srcfile" | psql -h localhost -U "$DB_USER" "$DB_DATABASE"
echo "Staging baseline data restored."
