#!/bin/sh
#
###########################
#  Linux install script   #
# ----------------------- #
# Tested on Debian wheezy #
###########################

echo 'Checking dependencies...'

# Rails is installed by bundler later
#echo -n 'Rails 3.2..	'
#if rails -v | grep -q 'Rails 3.2'; then
#    echo 'ok'
#else
#    echo 'not found'
#    exit 1
#fi

echo -n 'Ruby 1.9.3..	'
revision=$(ruby -v | grep -E -o '^ruby 1\.9\.([0-9]+)' | cut -d . -f 3)
if [ "$revision" -gt 2 ]; then
    echo 'ok'
else
    echo 'not found'
    exit 1
fi

echo -n 'PostgreSQL..	'
if psql -? > /dev/null 2>&1; then
    echo 'ok'
else
    echo 'not found'
    exit 1
fi


psqlCreateCommands="
  createuser -s ofn
  psql postgres -c \"ALTER USER ofn WITH ENCRYPTED PASSWORD 'f00d'\"
  createdb -O ofn open_food_network_dev
  createdb -O ofn open_food_network_test
  createdb -O ofn open_food_network_prod
"
PGPASSFILE=$(mktemp)
echo ''
echo -n 'Checking PostgreSQL database..	'
echo 'localhost:5432:open_food_network_dev:ofn:f00d1' > $PGPASSFILE
export PGPASSFILE
if psql -w -U ofn open_food_network_dev -c 'select 1' > /dev/null 2>&1; then
    echo 'ok'
else
    echo 'no access'
    echo ''
    echo 'Database needs setup. Try automatic setup with sudo? [yes]'
    read autosetup
    if [ -z "$autosetup" ] || [ "$autosetup" = "yes" ]; then
        if sudo su postgres -c "$psqlCreateCommands"; then
            echo 'User and databases created.'
        else
            echo 'Failed to create user and databases.'
            autosetup='no'
        fi
    else
        autosetup='no'
    fi
    if [ "$autosetup" = 'no' ]; then
        echo ''
        echo 'Execute the following commands as database admin user (e.g. postgres):'
        echo "$psqlCreateCommands"
        rm "$PGPASSFILE"
        exit 1
    fi
fi
rm "$PGPASSFILE"

echo ''
echo 'Installing all gems. That can take a while.'
bundle install

echo ''
echo 'Seeding database..'
bundle exec rake db:schema:load db:seed
echo 'Skipping sample data (out of date)'
#bundle exec rake openfoodnetwork:dev:load_sample_data
echo 'You can run `rails server` now to start.'

echo ''
echo 'Executing tests..'
bundle exec rake db:test:load
bundle exec rspec spec

if [ "$?" -eq 0 ]; then
    echo ''
    echo 'All done.'
    echo 'You can run `rails server` now.'
fi
