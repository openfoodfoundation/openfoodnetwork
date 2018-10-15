# When enqueuing a job to refresh the products cache for a particular distribution, there
# is no benefit in having more than one job waiting in the queue to be run.

# Imagine that an admin updates a product. This calls for the products cache to be
# updated, otherwise customers will see stale data.

# Now while that update is running, the admin makes another change to the product. Since this change
# has been made after the previous update started running, the already-running update will not
# include that change - we need another job. So we enqueue another one.

# Before that job starts running, our zealous admin makes yet another change. This time, there
# is a job running *and* there is a job that has not yet started to run. In this case, there's no
# benefit in enqueuing another job. When the previously enqueued job starts running, it will pick up
# our admin's update and include it. So we ignore this change (from a cache refreshment perspective)
# and go home happy to have saved our job worker's time.

module OpenFoodNetwork
  class ProductsCacheRefreshment
    def self.refresh(distributor, order_cycle)
      job = refresh_job(distributor, order_cycle)
      enqueue_job(job) unless pending_job?(job)
    end

    def self.refresh_job(distributor, order_cycle)
      RefreshProductsCacheJob.new(distributor.id, order_cycle.id)
    end
    private_class_method :refresh_job

    def self.pending_job?(job)
      Delayed::Job.
        where(locked_at: nil).
        where(handler: job.to_yaml).
        exists?
    end
    private_class_method :pending_job?

    def self.enqueue_job(job)
      Delayed::Job.enqueue job, priority: 10
    end
    private_class_method :enqueue_job
  end
end
