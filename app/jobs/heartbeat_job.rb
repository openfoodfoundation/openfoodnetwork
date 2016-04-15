class HeartbeatJob
  def perform
    Spree::Config.last_job_queue_heartbeat_at = Time.now
  end
end
