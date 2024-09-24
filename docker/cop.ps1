# This script runs RuboCop

Write-Host "bundle exec rubocop : runs rubocop" -ForegroundColor Blue
docker compose run web bundle exec rubocop