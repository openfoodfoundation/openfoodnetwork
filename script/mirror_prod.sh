#!/bin/bash

set -e

echo "drop database open_food_web_dev" | psql -h localhost -U ofw open_food_web_test
echo "create database open_food_web_dev" | psql -h localhost -U ofw open_food_web_test
ssh ofw-prod "pg_dump -h localhost -U openfoodweb openfoodweb_production |gzip" |gunzip |psql -h localhost -U ofw open_food_web_dev
