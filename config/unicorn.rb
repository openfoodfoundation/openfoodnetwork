preload_app true   # https://newrelic.com/docs/ruby/no-data-with-unicorn
worker_processes 4 # amount of unicorn workers to spin up
timeout 60         # restarts workers that hang for 30 seconds


# https://devcenter.heroku.com/articles/forked-pg-connections
before_fork do |server, worker|

  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!
end

after_fork do |server, worker|

  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to sent QUIT'
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection

end
