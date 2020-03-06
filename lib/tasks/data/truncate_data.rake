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
      warn_with_confirmation

      months_to_keep = args.months_to_keep.to_i
      TruncateData.new(months_to_keep).call
    end

    def warn_with_confirmation
      message = <<-MSG.strip_heredoc
      \n
      <%= color('This will permanently change DB contents. Please, make a backup first.', :yellow) %>
      Are you sure you want to proceed? (y/N)
      MSG
      exit unless HighLine.new.agree(message) { |q| q.default = "n" }
    end
  end
end
