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
    RSpec::Matchers.define :enqueue_job do |klass, options = {}|
      match do |event_proc|
        last_job_id_before = Delayed::Job.last.andand.id || 0

        begin
          event_proc.call
        rescue StandardError => e
          @exception = e
          raise e
        end

        @jobs_created = Delayed::Job.where('id > ?', last_job_id_before)

        @jobs_created.any? do |job|
          job = job.payload_object

          match = true
          match &= (job.class == klass)

          options.each_pair do |k, v|
            begin
              match &= (job[k] == v)
            rescue NameError
              match = false
            end
          end

          match
        end
      end

      failure_message_for_should do |event_proc|
        @exception || "expected #{klass} to be enqueued matching #{options.inspect} (#{@jobs_created.count} others enqueued)"
      end

      failure_message_for_should_not do |event_proc|
        @exception || "expected #{klass} to not be enqueued matching #{options.inspect}"
      end
    end
  end
end
