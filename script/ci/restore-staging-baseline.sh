#!/bin/bash

# Restore baseline data for staging in case a pull request messed with
# the database.

set -e

# Load default values if not already set.
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

# We want to re-create the database but it's still in use.
# The SQL query below is a workaround suppoting old postgresql versions.
#
# Once we have at least Postgresql 13, we can replace these SQL commands with:
#
#   DROP DATABASE IF EXISTS $DB_DATABASE WITH FORCE
#   CREATE DATABASE $DB_DATABASE
#
# Versions:
# - Ubuntu 16: psql 9.5
# - Ubuntu 18: psql 10
# - Ubuntu 20: psql 15 <-- switch here
psql -h localhost -U "$DB_USER" postgres <<EOF
REVOKE CONNECT ON DATABASE $DB_DATABASE FROM public;
ALTER DATABASE $DB_DATABASE CONNECTION LIMIT 0;
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE pid <> pg_backend_pid()
AND datname='$DB_DATABASE';
DROP DATABASE $DB_DATABASE;
CREATE DATABASE $DB_DATABASE;
EOF

gunzip -c "$srcfile" | psql -h localhost -U "$DB_USER" "$DB_DATABASE"
echo "Staging baseline data restored."
