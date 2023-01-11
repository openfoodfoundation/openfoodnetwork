# frozen_string_literal: true

# Forks into a separate process to contain memory usage and timeout errors.
class JobProcessor
  def self.perform_forked(job, *args)
    fork do
      Process.setproctitle("Job worker #{job.job_id}")
      job.perform(*args)

      # Exit is not a good idea within a Rails process but Rubocop doesn't know
      # that we are in a forked process.
      exit # rubocop:disable Rails/Exit
    end

    Process.waitall
  end
end
