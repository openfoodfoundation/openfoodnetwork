#!/bin/bash
set +e

docker-compose down -v --remove-orphans
wait
echo '###########################'
echo 'BEGIN: docker-compose build'
echo '###########################'
docker-compose build
echo '##############################'
echo 'FINISHED: docker-compose build'
echo '##############################'
