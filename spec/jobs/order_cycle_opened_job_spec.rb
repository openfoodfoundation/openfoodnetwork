# frozen_string_literal: true

require 'spec_helper'
require_relative '../../engines/dfc_provider/spec/support/authorization_helper'

RSpec.describe OrderCycleOpenedJob do
  include AuthorizationHelper

  let(:oc_opened_before) {
    create(:simple_order_cycle, orders_open_at: 1.hour.ago)
  }
  let(:oc_opened_now) {
    create(:simple_order_cycle, orders_open_at: Time.zone.now)
  }
  let(:oc_opening_soon) {
    create(:simple_order_cycle, orders_open_at: 1.minute.from_now)
  }

  it "enqueues jobs for recently opened order cycles only" do
    expect{ OrderCycleOpenedJob.perform_now }
      .to enqueue_job(OpenOrderCycleJob).with(oc_opened_now.id)
      .and enqueue_job(OpenOrderCycleJob).with(oc_opened_before.id).exactly(0).times
      .and enqueue_job(OpenOrderCycleJob).with(oc_opening_soon.id).exactly(0).times
  end

  describe "concurrency", concurrency: true do
    let(:breakpoint) { Mutex.new }

    it "doesn't place duplicate job when run concurrently" do
      pending "dunno why this doesn't work" # but then maybe this can be better handled in the sub-job.
      oc_opened_now

      # Pause jobs when placing new job:
      breakpoint.lock
      allow(OrderCycleOpenedJob).to(
        receive(:new).and_wrap_original do |method, *args|
          breakpoint.synchronize { nil }
          method.call(*args)
        end
      )

      expect {
        # Start two jobs in parallel:
        threads = [
          Thread.new { OrderCycleOpenedJob.perform_now },
          Thread.new { OrderCycleOpenedJob.perform_now },
        ]

        # Wait for both to jobs to pause.
        # This can reveal a race condition.
        sleep 0.1

        # Resume and complete both jobs:
        breakpoint.unlock
        threads.each(&:join)
      }
        .to enqueue_job(OpenOrderCycleJob).with(oc_opened_now.id).once
    end
  end
end
