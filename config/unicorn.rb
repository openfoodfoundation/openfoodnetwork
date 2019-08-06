# The following enables use of the Ruby 2.0+ Copy-On-Write feature
# for more efficient memory usage in Unicorn workers.

if ENV["RAILS_ENV"].in?('production', 'staging')
  preload_app true

  before_fork do |server, worker|
    defined?(ActiveRecord::Base) and
        ActiveRecord::Base.connection.disconnect!
  end

  after_fork do |server, worker|
    defined?(ActiveRecord::Base) and
        ActiveRecord::Base.establish_connection
  end
end
