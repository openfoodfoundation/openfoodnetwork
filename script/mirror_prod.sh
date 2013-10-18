#!/bin/bash

set -e

echo "drop database open_food_network_dev" | psql -h localhost -U ofn open_food_network_test
echo "create database open_food_network_dev" | psql -h localhost -U ofn open_food_network_test
ssh ofn-prod "pg_dump -h localhost -U openfoodweb openfoodweb_production |gzip" |gunzip |psql -h localhost -U ofn open_food_network_dev
