#!/bin/bash

set -e

ssh ofn-prod "pg_dump -h localhost -U openfoodweb openfoodweb_production |gzip" > db/backup/ofn-prod-`date +%Y%m%d`.sql.gz
