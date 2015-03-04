#!/bin/bash

# Usage: script/backup.sh [ofn-staging1|ofn-staging2|ofn-prod]

set -e

mkdir -p db/backup
ssh $1 "pg_dump -h localhost -U openfoodweb openfoodweb_production |gzip" > db/backup/$1-`date +%Y%m%d`.sql.gz
