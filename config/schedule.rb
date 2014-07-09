require 'whenever'

# Learn more: http://github.com/javan/whenever

env "MAILTO", "rohan@rohanmitchell.com"

# If we use -e with a file containing specs, rspec interprets it and filters out our examples
job_type :run_file, "cd :path; :environment_variable=:environment bundle exec script/rails runner :task :output"

every 1.day, at: '12:05am' do
  run_file "lib/open_food_network/integrity_checker.rb"
end

every 1.day, at: '2:45am' do
  rake 'db2fog:clean'
end

every 4.hours do
  rake 'db2fog:backup'
end
