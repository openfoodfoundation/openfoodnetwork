require './spec/support/enqueue_job_matcher'

module OpenFoodNetwork
  module DelayedJobHelper
    def run_job(job)
      clear_jobs
      Delayed::Job.enqueue job
      flush_jobs
    end

    # Process all pending Delayed jobs, keeping in mind jobs could spawn new
    # delayed job (so things might be added to the queue while processing)
    def flush_jobs(options = {})
      options[:ignore_exceptions] ||= false

      Delayed::Worker.new.work_off(100)

      unless options[:ignore_exceptions]
        Delayed::Job.all.each do |job|
          if job.last_error.present?
            throw "There was an error in a delayed job: #{job.last_error}"
          end
        end
      end
    end

    def clear_jobs
      Delayed::Job.delete_all
    end

    # expect { foo }.to enqueue_job MyJob, field1: 'foo', field2: 'bar'
    def enqueue_job(job, options = {})
      EnqueueJobMatcher.new(job, options)
    end
  end
end
