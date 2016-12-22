require 'spec_helper'

describe OrderCycleOpenCloseJob do
  let(:job) { OrderCycleOpenCloseJob.new }

  describe "running the job" do
    it "enqueues a StandingOrderPlacementJob" do
      expect{job.perform}.to enqueue_job StandingOrderPlacementJob
    end

    it "enqueues a StandingOrderConfirmJob" do
      expect{job.perform}.to enqueue_job StandingOrderConfirmJob
    end
  end
end
