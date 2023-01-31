# frozen_string_literal: true

# Forks into a separate process to contain memory usage and timeout errors.
class JobProcessor
  def self.perform_forked(job, *args)
    # Reports should abort when puma threads are killed to avoid wasting
    # resources. Nobody would be collecting the result. We still need to
    # implement a way to email or download reports later.
    timeout = ENV.fetch("RACK_TIMEOUT_WAIT_TIMEOUT", "30").to_i

    child = fork do
      Process.setproctitle("Job worker #{job.job_id}")
      Timeout.timeout(timeout) do
        job.perform(*args)
      end

      # Exit is not a good idea within a Rails process but Rubocop doesn't know
      # that we are in a forked process.
      exit # rubocop:disable Rails/Exit
    end

    # Wait for all forked child processes to exit
    Process.waitall
  ensure
    # If this Puma thread is interrupted then we need to detach the child
    # process to avoid it becoming a zombie.
    Process.detach(child)
  end
end
