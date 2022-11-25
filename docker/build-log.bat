START /B /WAIT docker-compose down -v --remove-orphans
echo '###########################'
echo 'BEGIN: docker-compose build'
echo 'Set up the Docker containers'
echo '###########################'
docker-compose build
echo '##############################'
echo 'FINISHED: docker-compose build'
echo '##############################'