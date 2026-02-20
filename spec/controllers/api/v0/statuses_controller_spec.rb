# frozen_string_literal: true

module Api
  RSpec.describe V0::StatusesController do
    render_views

    describe "job queue status" do
      it "returns alive when up to date" do
        Spree::Config.last_job_queue_heartbeat_at = Time.now.in_time_zone
        get :job_queue
        expect(response).to have_http_status :ok
        expect(response.body).to eq({ alive: true }.to_json)
      end

      it "returns dead otherwise" do
        Spree::Config.last_job_queue_heartbeat_at = 10.minutes.ago
        get :job_queue
        expect(response).to have_http_status :ok
        expect(response.body).to eq({ alive: false }.to_json)
      end

      it "returns dead when no heartbeat recorded" do
        Spree::Config.last_job_queue_heartbeat_at = nil
        get :job_queue
        expect(response).to have_http_status :ok
        expect(response.body).to eq({ alive: false }.to_json)
      end
    end
  end
end
