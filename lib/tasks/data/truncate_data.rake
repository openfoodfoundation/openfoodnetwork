# frozen_string_literal: true

require 'highline'
require 'tasks/data/truncate_data'

# This task can be used to significantly reduce the size of a database
#   This is used for example when loading live data into a staging server
#   This way the staging server is not overloaded with too much data
namespace :ofn do
  namespace :data do
    desc 'Truncate data'
    task :truncate, [:months_to_keep] => :environment do |_task, args|
      guard_and_warn

      months_to_keep = args.months_to_keep.to_i
      TruncateData.new(months_to_keep).call
    end

    def guard_and_warn
      if Rails.env.production?
        Rails.logger.info("This task cannot be executed in production")
        exit
      end

      message = "\n <%= color('This will permanently change DB contents', :yellow) %>,
                are you sure you want to proceed? (y/N)"
      exit unless HighLine.new.agree(message) { |q| q.default = "n" }
    end
  end
end
