# This script launches the whole stack of containers (web server, database, webpack, redis, etc.)
$DateTime=Get-Date -Format "yyyyMMdd-HHmmss"

Write-Host "Docker-compose up: launches the whole stack of containers" -ForegroundColor Blue
docker-compose.exe up -d > log/server-$DateTime.log 2>&1
Write-Host "Docker-compose up finished : View this app in your web browser at http://localhost:3000/" -ForegroundColor Blue