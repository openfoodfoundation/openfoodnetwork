# frozen_string_literal: true

require 'highline'
require 'tasks/data/truncate_data'

# This task can be used to significantly reduce the size of a database
#   This is used for example when loading live data into a staging server
#   This way the staging server is not overloaded with too much data
#
# This is also aimed at implementing data archiving. We assume data older than
# 2 years can be safely removed and restored from a backup. This gives room for
# hubs to do their tax declaration.
#
# It's a must to perform a backup right before executing this. Then, to allow
# for a later data recovery we need to keep track of the exact moment this rake
# task was executed.
#
# Execute this in production only when the instance users are sleeping to avoid any trouble.
#
# Example:
#
# $ bundle exec rake "ofn:data:truncate[24]"
#
# This will remove data older than 2 years (24 months).
namespace :ofn do
  namespace :data do
    desc 'Truncate data'
    task :truncate, [:months_to_keep] => :environment do |_task, args|
      warn_with_confirmation

      TruncateData.new(args.months_to_keep).call
    end

    def warn_with_confirmation
      message = <<-MSG.strip_heredoc
      \n
      <% highlighted_message = "This will permanently change DB contents. This is not meant to be run in production as it needs more thorough testing." %>
      <%= color(highlighted_message, :blink, :on_red) %>
      Are you sure you want to proceed? (y/N)
      MSG

      exit unless HighLine.new.agree(message) { |question| question.default = "N" }
    end
  end
end
