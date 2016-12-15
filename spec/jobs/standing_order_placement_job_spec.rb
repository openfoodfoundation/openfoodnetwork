require 'spec_helper'

describe StandingOrderPlacementJob do

  describe "finding proxy_orders for the specified order cycle" do
    let(:shop) { create(:distributor_enterprise) }
    let(:order_cycle1) { create(:simple_order_cycle, coordinator: shop, orders_close_at: 10.minutes.from_now) }
    let(:order_cycle2) { create(:simple_order_cycle, coordinator: shop) }
    let(:schedule) { create(:schedule, order_cycles: [order_cycle1, order_cycle2]) }
    let(:standing_order1) { create(:standing_order, shop: shop, schedule: schedule, begins_at: 9.minutes.from_now, ends_at: 11.minutes.from_now) }
    let(:standing_order2) { create(:standing_order, shop: shop, schedule: schedule, begins_at: 9.minutes.from_now, ends_at: 11.minutes.from_now, paused_at: 1.minute.ago) }
    let(:standing_order3) { create(:standing_order, shop: shop, schedule: schedule, begins_at: 9.minutes.from_now, ends_at: 11.minutes.from_now, canceled_at: 1.minute.ago) }
    let(:standing_order4) { create(:standing_order, shop: shop, schedule: schedule, begins_at: 11.minutes.from_now, ends_at: 20.minutes.from_now) }
    let(:standing_order5) { create(:standing_order, shop: shop, schedule: schedule, begins_at: 1.minute.ago, ends_at: 9.minutes.from_now) }
    let!(:proxy_order1) { create(:proxy_order, standing_order: standing_order1, order_cycle: order_cycle2) } # OC Mismatch
    let!(:proxy_order2) { create(:proxy_order, standing_order: standing_order2, order_cycle: order_cycle1) } # Paused
    let!(:proxy_order3) { create(:proxy_order, standing_order: standing_order3, order_cycle: order_cycle1) } # Cancelled
    let!(:proxy_order4) { create(:proxy_order, standing_order: standing_order4, order_cycle: order_cycle1) } # Begins after OC close
    let!(:proxy_order5) { create(:proxy_order, standing_order: standing_order5, order_cycle: order_cycle1) } # Ends before OC close
    let!(:proxy_order6) { create(:proxy_order, standing_order: standing_order1, order_cycle: order_cycle1) } # OK

    let!(:job) { StandingOrderPlacementJob.new(order_cycle1) }

    it "only returns not_canceled proxy_orders for the relevant order cycle" do
      proxy_orders = job.send(:proxy_orders)
      expect(proxy_orders).to include proxy_order6
      expect(proxy_orders).to_not include proxy_order1, proxy_order2, proxy_order3, proxy_order4, proxy_order5
    end
  end

  describe "processing an order containing items with insufficient stock" do
    let(:order_cycle) { create(:simple_order_cycle) }
    let(:order) { create(:order, order_cycle: order_cycle) }
    let(:variant1) { create(:variant, count_on_hand: 5) }
    let(:variant2) { create(:variant, count_on_hand: 2) }
    let(:variant3) { create(:variant, count_on_hand: 0) }
    let(:line_item1) { create(:line_item, order: order, variant: variant1, quantity: 5) }
    let(:line_item2) { create(:line_item, order: order, variant: variant2, quantity: 2) }
    let(:line_item3) { create(:line_item, order: order, variant: variant3, quantity: 0) }

    let!(:job) { StandingOrderPlacementJob.new(order_cycle) }

    before do
      Spree::Config.set(:allow_backorders, false)
      line_item1.update_attribute(:quantity, 3)
      line_item2.update_attribute(:quantity, 3)
      line_item3.update_attribute(:quantity, 3)
    end

    it "caps quantity at the stock level, and reports the change" do
      changes = job.send(:cap_quantity_and_store_changes, order.reload)
      expect(line_item1.reload.quantity).to be 3 # not capped
      expect(line_item2.reload.quantity).to be 2 # capped
      expect(line_item3.reload.quantity).to be 0 # capped
      expect(changes[line_item2.id]).to be 3
      expect(changes[line_item3.id]).to be 3
    end
  end

  describe "processing a standing order order" do
    let(:standing_order) { create(:standing_order, with_items: true) }
    let(:proxy_order) { create(:proxy_order, standing_order: standing_order) }
    let!(:order) { proxy_order.initialise_order! }
    let(:changes) { {} }

    let!(:job) { StandingOrderPlacementJob.new(proxy_order.order_cycle) }

    before do
      expect_any_instance_of(Spree::Payment).to_not receive(:process!)
      allow(job).to receive(:cap_quantity_and_store_changes) { changes }
      allow(job).to receive(:send_placement_email)
    end

    context "when the order is already complete" do
      before { while !order.completed? do break unless order.next! end }

      it "ignores it" do
        ActionMailer::Base.deliveries.clear
        expect{job.send(:process, order)}.to_not change{order.reload.state}
        expect(order.payments.first.state).to eq "checkout"
        expect(ActionMailer::Base.deliveries.count).to be 0
      end
    end

    context "when the order is not already complete" do
      it "processes the order to completion, but does not process the payment" do
        # If this spec starts complaining about no shipping methods being available
        # on CI, there is probably another spec resetting the currency though Rails.cache.clear
        ActionMailer::Base.deliveries.clear
        expect{job.send(:process, order)}.to change{order.reload.completed_at}.from(nil)
        expect(order.completed_at).to be_within(5.seconds).of Time.now
        expect(order.payments.first.state).to eq "checkout"
      end

      it "does not enqueue confirmation emails" do
        expect{job.send(:process, order)}.to_not enqueue_job ConfirmOrderJob
        expect(job).to have_received(:send_placement_email).with(order, changes).once
      end
    end
  end

  describe "sending placement email" do
    let(:standing_order) { create(:standing_order, with_items: true) }
    let(:proxy_order) { create(:proxy_order, standing_order: standing_order) }
    let!(:order) { proxy_order.initialise_order! }
    let(:mail_mock) { double(:mailer_mock) }
    let(:changes) { double(:changes) }

    let!(:job) { StandingOrderPlacementJob.new(proxy_order.order_cycle) }

    before do
      allow(Spree::OrderMailer).to receive(:standing_order_email) { mail_mock }
      allow(mail_mock).to receive(:deliver)
    end

    context "when the order is complete" do
      before { while !order.completed? do break unless order.next! end }

      it "sends the email" do
        job.send(:send_placement_email, order, changes)
        expect(Spree::OrderMailer).to have_received(:standing_order_email).with(order.id, 'placement', changes)
        expect(mail_mock).to have_received(:deliver)
      end
    end

    context "when the order is incomplete" do
      it "does not send the email" do
        job.send(:send_placement_email, order, changes)
        expect(Spree::OrderMailer).to_not have_received(:standing_order_email)
        expect(mail_mock).to_not have_received(:deliver)
      end
    end
  end
end
