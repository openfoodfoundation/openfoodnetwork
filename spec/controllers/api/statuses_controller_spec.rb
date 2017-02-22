require 'spec_helper'

module Api
  describe StatusesController, type: :controller do
    render_views

    describe "job queue status" do
      it "returns alive when up to date" do
        Spree::Config.last_job_queue_heartbeat_at = Time.now
        spree_get :job_queue
        response.should be_success
        response.body.should == {alive: true}.to_json
      end

      it "returns dead otherwise" do
        Spree::Config.last_job_queue_heartbeat_at = 10.minutes.ago
        spree_get :job_queue
        response.should be_success
        response.body.should == {alive: false}.to_json
      end

      it "returns dead when no heartbeat recorded" do
        Spree::Config.last_job_queue_heartbeat_at = nil
        spree_get :job_queue
        response.should be_success
        response.body.should == {alive: false}.to_json
      end
    end
  end
end
