#!/bin/bash

# This script destroys all Docker containers but leaves the Docker images alone.

echo '------------------------------------------'
echo 'Killing and removing all Docker containers'
for i in $(docker ps -a -q)
do
  docker kill $i; wait;
  docker rm -f $i; wait;
done;

echo '------------'
echo 'docker ps -a'
docker ps -a
