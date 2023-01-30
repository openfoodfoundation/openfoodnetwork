# This script does :
# - build the Docker container and log the output of several containers in a unique "build-yyyyMMdd-HHmmss.log" file
# - seed the app with sample data and log the output in "seed-yyyyMMdd-HHmmss.log" file

$DateTime=Get-Date -Format "yyyyMMdd-HHmmss"

docker/build-log.ps1 > log/build-$DateTime.log 2>&1
docker/seed.ps1  > log/seed-$DateTime.log 2>&1
