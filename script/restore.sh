#!/bin/bash

# Usage: script/restore.sh [file.sql.gz]

set -e

echo "drop database open_food_network_dev" | psql -h localhost -U ofn open_food_network_test
echo "create database open_food_network_dev" | psql -h localhost -U ofn open_food_network_test
gunzip -c $1 |psql -h localhost -U ofn open_food_network_dev
