require 'spec_helper'

describe StandingOrderConfirmJob do
  let(:job) { StandingOrderConfirmJob.new }

  describe "finding proxy_orders that are ready to be confirmed" do
    let(:shop) { create(:distributor_enterprise) }
    let(:order_cycle1) { create(:simple_order_cycle, coordinator: shop, orders_close_at: 59.minutes.ago, updated_at: 1.day.ago) }
    let(:order_cycle2) { create(:simple_order_cycle, coordinator: shop, orders_close_at: 61.minutes.ago, updated_at: 1.day.ago) }
    let(:schedule) { create(:schedule, order_cycles: [order_cycle1, order_cycle2]) }
    let(:standing_order) { create(:standing_order, shop: shop, schedule: schedule) }
    let!(:proxy_order) { create(:proxy_order, standing_order: standing_order, order_cycle: order_cycle1, placed_at: 5.minutes.ago, order: create(:order, completed_at: 1.minute.ago)) }
    let(:proxy_orders) { job.send(:proxy_orders) }

    it "returns proxy orders that meet all of the criteria" do
      expect(proxy_orders).to include proxy_order
    end

    it "ignores proxy orders where the OC closed more than 1 hour ago" do
      proxy_order.update_attributes!(order_cycle_id: order_cycle2.id)
      expect(proxy_orders).to_not include proxy_order
    end

    it "ignores proxy orders for paused standing orders" do
      standing_order.update_attributes!(paused_at: 1.minute.ago)
      expect(proxy_orders).to_not include proxy_order
    end

    it "ignores proxy orders for cancelled standing orders" do
      standing_order.update_attributes!(canceled_at: 1.minute.ago)
      expect(proxy_orders).to_not include proxy_order
    end

    it "ignores cancelled proxy orders" do
      proxy_order.update_attributes!(canceled_at: 5.minute.ago)
      expect(proxy_orders).to_not include proxy_order
    end

    it "ignores proxy orders without a completed order" do
      proxy_order.order.completed_at = nil
      proxy_order.order.save!
      expect(proxy_orders).to_not include proxy_order
    end

    it "ignores proxy orders without an associated order" do
      proxy_order.update_attributes!(order_id: nil)
      expect(proxy_orders).to_not include proxy_order
    end

    it "ignores proxy orders that haven't been placed yet" do
      proxy_order.update_attributes!(placed_at: nil)
      expect(proxy_orders).to_not include proxy_order
    end

    it "ignores proxy orders that have already been confirmed" do
      proxy_order.update_attributes!(confirmed_at: 1.second.ago)
      expect(proxy_orders).to_not include proxy_order
    end
  end

  describe "performing the job" do
    context "when unconfirmed proxy_orders exist" do
      let!(:proxy_order) { create(:proxy_order) }

      before do
        proxy_order.initialise_order!
        allow(job).to receive(:proxy_orders) { ProxyOrder.where(id: proxy_order.id) }
        allow(job).to receive(:process)
      end

      it "marks confirmable proxy_orders as processed by setting confirmed_at" do
        expect{job.perform}.to change{proxy_order.reload.confirmed_at}
        expect(proxy_order.confirmed_at).to be_within(5.seconds).of Time.now
      end

      it "processes confirmable proxy_orders" do
        job.perform
        expect(job).to have_received(:process).with(proxy_order.reload.order)
      end
    end
  end

  describe "finding recently closed order cycles" do
    let!(:order_cycle1) { create(:simple_order_cycle, orders_close_at: 61.minutes.ago, updated_at: 61.minutes.ago) }
    let!(:order_cycle2) { create(:simple_order_cycle, orders_close_at: nil, updated_at: 59.minutes.ago) }
    let!(:order_cycle3) { create(:simple_order_cycle, orders_close_at: 61.minutes.ago, updated_at: 59.minutes.ago) }
    let!(:order_cycle4) { create(:simple_order_cycle, orders_close_at: 59.minutes.ago, updated_at: 61.minutes.ago) }
    let!(:order_cycle5) { create(:simple_order_cycle, orders_close_at: 1.minute.from_now) }

    it "returns closed order cycles whose orders_close_at or updated_at date is within the last hour" do
      order_cycles = job.send(:recently_closed_order_cycles)
      expect(order_cycles).to include order_cycle3, order_cycle4
      expect(order_cycles).to_not include order_cycle1, order_cycle2, order_cycle5
    end
  end

  describe "processing an order" do
    let(:shop) { create(:distributor_enterprise) }
    let(:order_cycle1) { create(:simple_order_cycle, coordinator: shop) }
    let(:order_cycle2) { create(:simple_order_cycle, coordinator: shop) }
    let(:schedule1) { create(:schedule, order_cycles: [order_cycle1, order_cycle2]) }
    let(:standing_order1) { create(:standing_order, shop: shop, schedule: schedule1, with_items: true) }
    let(:proxy_order) { create(:proxy_order, standing_order: standing_order1) }
    let(:order) { proxy_order.initialise_order! }

    before do
      while !order.completed? do break unless order.next! end
      allow(job).to receive(:send_confirm_email).and_call_original
      Spree::MailMethod.create!(
        environment: Rails.env,
        preferred_mails_from: 'spree@example.com'
      )
    end

    it "sends only a standing order confirm email, no regular confirmation emails" do
      ActionMailer::Base.deliveries.clear
      expect{job.send(:process, order)}.to_not enqueue_job ConfirmOrderJob
      expect(job).to have_received(:send_confirm_email).with(order).once
      expect(ActionMailer::Base.deliveries.count).to be 1
    end

    context "when payments need to be processed" do
      let(:payment_updater_mock) { double(:payment_updater) }
      let(:payment) { double(:payment, amount: 10) }

      before do
        allow(order).to receive(:payment_total) { 0 }
        allow(order).to receive(:total) { 10 }
        allow(order).to receive(:pending_payments) { [payment] }
      end

      it "updates the payment total and processes payments as required" do
        expect(OpenFoodNetwork::StandingOrderPaymentUpdater).to receive(:new) { payment_updater_mock }
        expect(payment_updater_mock).to receive(:update!) { true }
        expect(payment).to receive(:process!)
        expect(payment).to receive(:completed?) { true }
        job.send(:process, order)
      end
    end
  end
end
