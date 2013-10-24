#!/bin/bash

# Usage: script/mirror_db.sh [ofn-staging1|ofn-staging2|ofn-prod]

set -e

echo "drop database open_food_network_dev" | psql -h localhost -U ofn open_food_network_test
echo "create database open_food_network_dev" | psql -h localhost -U ofn open_food_network_test
ssh $1 "pg_dump -h localhost -U openfoodweb openfoodweb_production |gzip" |gunzip |psql -h localhost -U ofn open_food_network_dev
