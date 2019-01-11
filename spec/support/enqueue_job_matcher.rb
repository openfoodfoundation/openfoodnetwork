class EnqueueJobMatcher
  module Hooks
    @@successful_jobs = []

    def success(job)
      @@successful_jobs << job
    end

    def self.successful_jobs
      @@successful_jobs
    end
  end

  def initialize(klass, options)
    @klass = klass
    @options = options

    klass.include(Hooks)
  end

  def supports_block_expectations?
    true
  end

  def matches?(event_proc)
    raise ArgumentError, 'enqueue_job only supports block expectations' unless Proc === event_proc

    last_job_id_before = Delayed::Job.last.andand.id || 0

    begin
      event_proc.call
      check(last_job_id_before)
    rescue StandardError => e
      @exception = e
      raise e
    end
  end

  def failure_message
    count = 0
    count = @jobs_created.count if @jobs_created

    @exception || "expected #{klass} to be enqueued matching #{options.inspect} (#{count} others enqueued)"
  end

  def failure_message_when_negated
    @exception || "expected #{klass} to not be enqueued matching #{options.inspect}"
  end

  private

  attr_reader :klass, :options

  def check(last_job_id_before)
    @jobs_created = if Delayed::Worker.delay_jobs
                      Delayed::Job.where('id > ?', last_job_id_before)
                    else
                      Hooks.successful_jobs
                    end

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
end
