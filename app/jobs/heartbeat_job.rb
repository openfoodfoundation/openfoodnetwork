# frozen_string_literal: true

class HeartbeatJob < ApplicationJob
  def perform
    Spree::Config.last_job_queue_heartbeat_at = Time.now.in_time_zone
  end
end
