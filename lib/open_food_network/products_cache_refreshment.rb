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
      unless pending_job? distributor, order_cycle
        enqueue_job distributor, order_cycle
      end
    end


    private

    def self.pending_job?(distributor, order_cycle)
      # To inspect each job, we need to deserialize the payload.
      # This is slow, and if it's a problem in practice, we could pre-filter in SQL
      # for handlers matching the class name, distributor id and order cycle id.

      Delayed::Job.
        where(locked_at: nil).
        map(&:payload_object).
        select { |j|
          j.class == RefreshProductsCacheJob &&
          j.distributor_id == distributor.id &&
          j.order_cycle_id == order_cycle.id
        }.any?
    end

    def self.enqueue_job(distributor, order_cycle)
      Delayed::Job.enqueue RefreshProductsCacheJob.new(distributor.id, order_cycle.id), priority: 10
    end
  end
end
