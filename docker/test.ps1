# This test script :
# - prepares the database for rspec tests
# - launches the rspec tests
$DateTime=Get-Date -Format "yyyyMMdd-HHmmss"

Write-Host "bundle exec rake db:test:prepare : prepare the database for rspec tests" -ForegroundColor Blue
docker-compose.exe run web bundle exec rake db:test:prepare > log/test-prepare-$DateTime.log 2>&1
Write-Host "bundle exec rspec spec : launch the rspec tests" -ForegroundColor Blue
docker-compose.exe run web bundle exec rspec spec > log/test-rspec-$DateTime.log 2>&1