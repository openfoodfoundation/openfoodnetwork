Write-Host "Docker cleaning: remove old containers" -ForegroundColor Blue
docker compose down -v --remove-orphans
Write-Host "Docker build: set up the docker containers" -ForegroundColor Blue
docker compose build
Write-Host "Docker build finished"