# frozen_string_literal: true

require 'sidekiq/api'

namespace :ofn do
  task reset: :environment do
    Rake::Task["ofn:reset_sidekiq"].invoke
    Rake::Task["db:reset"].invoke
  end

  task reset_sidekiq: :environment do
    # Clear retry set
    Sidekiq::RetrySet.new.clear

    # Clear scheduled jobs
    Sidekiq::ScheduledSet.new.clear

    # Clear 'Dead' jobs statistics
    Sidekiq::DeadSet.new.clear

    # Clear 'Processed' and 'Failed' jobs statistics
    Sidekiq::Stats.new.reset

    # Clear all queues
    Sidekiq::Queue.all.map(&:clear)
  end
end
