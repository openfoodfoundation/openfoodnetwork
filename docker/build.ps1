# This script does :
# - build the Docker container and log the output of several containers in a unique "build-yyyyMMdd-HHmmss.log" file
# - seed the app with sample data and log the output in "seed-yyyyMMdd-HHmmss.log" file

$DateTime=Get-Date -Format "yyyyMMdd-HHmmss"

# Check if an argument is provided
if ($args.Count -gt 0) {
    # Run the build command with the argument and log output
    docker/build-log.ps1 $args[0] > log/build-$DateTime.log 2>&1
} else {
    docker/build-log.ps1 > log/build-$DateTime.log 2>&1
}
docker/seed.ps1  > log/seed-$DateTime.log 2>&1
