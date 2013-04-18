preload_app true   # https://newrelic.com/docs/ruby/no-data-with-unicorn
worker_processes 4 # amount of unicorn workers to spin up
timeout 30         # restarts workers that hang for 30 seconds
