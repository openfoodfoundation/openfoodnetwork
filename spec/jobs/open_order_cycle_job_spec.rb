# frozen_string_literal: true

RSpec.describe OpenOrderCycleJob do
  let(:now){ Time.zone.now }
  let(:order_cycle) { create(:simple_order_cycle, orders_open_at: now) }
  subject { OpenOrderCycleJob.perform_now(order_cycle.id) }

  before do
    freeze_time
  end

  it "marks as open" do
    expect {
      subject
      order_cycle.reload
    }
      .to change { order_cycle.opened_at }

    expect(order_cycle.opened_at).to be_within(1).of(now)
  end

  it "enqueues webhook job" do
    expect(OrderCycles::WebhookService)
      .to receive(:create_webhook_job).with(order_cycle, 'order_cycle.opened', now).once

    subject
  end

  describe "syncing remote products" do
    let!(:user) { create(:testdfc_user, owned_enterprises: [enterprise]) }

    let(:enterprise) { create(:supplier_enterprise) }
    let!(:variant) { create(:variant, name: "Sauce", supplier_id: enterprise.id) }
    let!(:variant_discontinued) {
      create(:variant, name: "Shiraz 1971", supplier_id: enterprise.id)
    }
    let!(:order_cycle) {
      create(
        :simple_order_cycle,
        orders_open_at: now,
        suppliers: [enterprise],
        variants: [variant, variant_discontinued]
      )
    }

    it "synchronises products from a FDC catalog", vcr: true do
      user.update!(oidc_account: build(:testdfc_account))
      # One current product is existing in OFN
      product_id =
        "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts/44519466467635"
      variant.semantic_links << SemanticLink.new(semantic_id: product_id)

      # One discontinued product is existing in OFN
      old_product_id =
        "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts/44519466467635-disc"
      variant_discontinued.semantic_links << SemanticLink.new(semantic_id: old_product_id)

      expect {
        subject
        variant.reload
        variant_discontinued.reload
        order_cycle.reload
      }.to change { order_cycle.opened_at }
        .and change { enterprise.supplied_products.count }.by(0) # It shouldn't add, only update
        .and change { variant.display_name }
        .and change { variant.unit_value }
        # 18.85 wholesale variant price divided by 12 cans in the slab.
        .and change { variant.price }.to(1.57)
        .and change { variant.on_demand }.to(true)
        .and change { variant.on_hand }.by(0)
        .and change { variant_discontinued.on_hand }.to(0)
        .and query_database 58
    end
  end

  context "with cloned order cycle" do
    subject { OpenOrderCycleJob.perform_now(cloned_order_cycle.id) }

    let!(:cloned_order_cycle) do
      order_cycle.update!(opened_at: now - 5.minutes)

      coc = OrderCycles::CloneService.new(order_cycle.reload).create
      coc.update!(orders_open_at: now + 5.minutes)
      coc.reload

      coc
    end

    it "marks as open" do
      expect {
        subject
        cloned_order_cycle.reload
      }
        .to change { cloned_order_cycle.opened_at }

      expect(cloned_order_cycle.opened_at).to be_within(1).of(now)
    end

    it "enqueues webhook job" do
      expect(OrderCycles::WebhookService)
        .to receive(:create_webhook_job).with(cloned_order_cycle, 'order_cycle.opened', now).once

      subject
    end
  end

  describe "concurrency", concurrency: true do
    let(:breakpoint) { Mutex.new }

    it "doesn't open order cycle twice" do
      # Pause in the middle of the job to test if the second job is trying
      # to do the same thing at the same time.
      breakpoint.lock
      expect_any_instance_of(OpenOrderCycleJob).to(
        receive(:sync_remote_variants).and_wrap_original do |method, *args|
          breakpoint.synchronize { nil }
          method.call(*args)
        end
      )

      expect(OrderCycles::WebhookService)
        .to receive(:create_webhook_job).with(order_cycle, 'order_cycle.opened', now).once

      # Start two jobs in parallel:
      threads = [1, 2].map do
        Thread.new do
          # Disable printing expected error
          Thread.current.report_on_exception = false

          OpenOrderCycleJob.perform_now(order_cycle.id)
        end
      end

      # Wait for both to jobs to pause.
      # This can reveal a race condition.
      sleep 0.1

      # Resume and complete both jobs:
      breakpoint.unlock

      # Join the threads until an error is raised.
      # We expect one of them to raise an error but we don't know which one.
      expect {
        threads.pop.join
        threads.pop.join
      }.to raise_error ActiveRecord::RecordNotFound

      # If the first `join` raised an error, we still need to wait for the
      # second thread to finish:
      threads.pop.join if threads.present?
    end
  end
end
