# Force manual loading of rails application to get all env variables from dotenv-rails when running whenever cmd
require File.expand_path('../environment',  __FILE__)

require 'whenever'
require 'yaml'

# Learn more: http://github.com/javan/whenever

env "MAILTO", ENV["SCHEDULE_NOTIFICATIONS"] if ENV["SCHEDULE_NOTIFICATIONS"]

# If we use -e with a file containing specs, rspec interprets it and filters out our examples
job_type :run_file, "cd :path; :environment_variable=:environment bundle exec script/rails runner :task :output"

every 1.month, at: '4:30am' do
  rake 'ofn:data:remove_transient_data'
end

every 1.day, at: '2:45am' do
  rake 'db2fog:clean' if ENV['S3_BACKUPS_BUCKET']
end

every 4.hours do
  rake 'db2fog:backup' if ENV['S3_BACKUPS_BUCKET']
end
