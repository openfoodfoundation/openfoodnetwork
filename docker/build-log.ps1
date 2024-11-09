Write-Host "Docker cleaning: remove old containers" -ForegroundColor Blue
docker compose down -v --remove-orphans
Write-Host "Docker build: set up the docker containers" -ForegroundColor Blue

# Check if an argument is provided
if ($args.Count -gt 0) {
    # Run the build command with the argument and log output
    docker build -f $1 .
} else {
	docker compose build
}
Write-Host "Docker build finished"