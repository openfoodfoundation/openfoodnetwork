require 'whenever'
require 'yaml'

# Learn more: http://github.com/javan/whenever

app_config = YAML.load_file(File.join(__dir__, 'application.yml'))

env "MAILTO", app_config["SCHEDULE_NOTIFICATIONS"] if app_config["SCHEDULE_NOTIFICATIONS"]

# If we use -e with a file containing specs, rspec interprets it and filters out our examples
job_type :run_file, "cd :path; :environment_variable=:environment bundle exec script/rails runner :task :output"
job_type :run_command, "cd :path; :environment_variable=:environment bundle exec :task :args"
job_type :enqueue_job,  "cd :path; :environment_variable=:environment bundle exec script/enqueue :task :priority :output"

every 1.month, at: '4:30am' do
  rake 'ofn:data:remove_transient_data'
end

every 4.hours do
  if app_config['S3_BACKUPS_BUCKET']
    run_command "backup", args: "perform --trigger s3_backup --config config/backup.rb"
  end
end

every 5.minutes do
  enqueue_job 'HeartbeatJob', priority: 0
  enqueue_job 'SubscriptionPlacementJob', priority: 0
  enqueue_job 'SubscriptionConfirmJob', priority: 0
end
