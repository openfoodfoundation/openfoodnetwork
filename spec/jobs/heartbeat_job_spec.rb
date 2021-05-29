# frozen_string_literal: true

require 'spec_helper'

describe HeartbeatJob do
  context "with time frozen" do
    let(:run_time) { Time.zone.local(2016, 4, 13, 13, 0, 0) }

    before { Spree::Config.last_job_queue_heartbeat_at = nil }

    around do |example|
      Timecop.freeze(run_time) { example.run }
    end

    it "updates the last_job_queue_heartbeat_at config var" do
      HeartbeatJob.perform_now
      expect(Time.parse(Spree::Config.last_job_queue_heartbeat_at).in_time_zone).to eq(run_time)
    end
  end
end
