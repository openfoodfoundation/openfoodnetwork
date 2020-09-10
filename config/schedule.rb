require 'whenever'
require 'yaml'

# Learn more: http://github.com/javan/whenever

app_config = YAML.load_file(File.join(__dir__, 'application.yml'))

env "MAILTO", app_config["SCHEDULE_NOTIFICATIONS"] if app_config["SCHEDULE_NOTIFICATIONS"]

# If we use -e with a file containing specs, rspec interprets it and filters out our examples
job_type :run_file, "cd :path; :environment_variable=:environment bundle exec script/rails runner :task :output"
job_type :enqueue_job,  "cd :path; :environment_variable=:environment bundle exec script/enqueue :task :priority :output"

every 1.month do
  rake 'ofn:data:remove_transient_data'
end

every 1.day, at: '2:45am' do
  rake 'db2fog:clean' if app_config['S3_BACKUPS_BUCKET']
end

every 4.hours do
  rake 'db2fog:backup' if app_config['S3_BACKUPS_BUCKET']
end

every 5.minutes do
  enqueue_job 'HeartbeatJob', priority: 0
  enqueue_job 'SubscriptionPlacementJob', priority: 0
  enqueue_job 'SubscriptionConfirmJob', priority: 0
end
