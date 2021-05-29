Delayed::Worker.logger = ActiveSupport::Logger.new(Rails.root.join('log', 'delayed_job.log'))
Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.max_run_time = 15.minutes

# Uncomment the next line if you want jobs to be executed straight away.
# For example you want emails to be opened in your browser while testing.
#Delayed::Worker.delay_jobs = false

# Notify bugsnag when a job fails
# Code adapted from http://trevorturk.com/2011/01/25/notify-hoptoad-if-theres-an-exception-in-delayedjob/
class Delayed::Worker
  alias_method :original_handle_failed_job, :handle_failed_job

  def handle_failed_job(job, error)
    Bugsnag.notify(error)
    original_handle_failed_job(job, error)
  end

  def self.before_fork
    ActiveRecord::Base.clear_all_connections!
    Redis.current.disconnect! if defined?(Redis)
  end

  def self.after_fork
    ActiveRecord::Base.establish_connection(Rails.env.to_sym)

    unless ActiveRecord::Base.connection.query_cache.empty?
      ActiveRecord::Base.connection.query_cache.clear
    end

    Delayed::Worker.logger.reopen

    Rails.logger.reopen
    ActiveRecord::Base.logger     = Rails.logger
    ActionController::Base.logger = Rails.logger
    ActionMailer::Base.logger     = Rails.logger
    Rails.cache.logger            = Rails.logger
  end
end
