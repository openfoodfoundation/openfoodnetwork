Write-Host "Docker cleaning: remove old containers" -ForegroundColor Blue
docker-compose.exe down -v --remove-orphans
Write-Host "Docker build: set up the docker containers" -ForegroundColor Blue
docker-compose.exe build
Write-Host "Docker build finished"