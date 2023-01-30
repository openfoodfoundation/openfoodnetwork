# This is the data seeding script :
# - reset the database
# - prepare the database
# - seed the database with sample data

Write-Host "bundle exec rake db:reset : reset the dev and test databases" -ForegroundColor Blue
docker-compose.exe run web bundle exec rake db:reset

Write-Host "bundle exec rake db:test:prepare : prepare the database" -ForegroundColor Blue
docker-compose.exe run web bundle exec rake db:test:prepare

Write-Host "bundle exec rake ofn:sample_data : seed the database with sample data" -ForegroundColor Blue
docker-compose.exe run web bundle exec rake ofn:sample_data