require 'spec_helper'

describe StandingOrderPlacementJob do
  let(:job) { StandingOrderPlacementJob.new }

  describe "finding proxy_orders that are ready to be placed" do
    let(:shop) { create(:distributor_enterprise) }
    let(:order_cycle1) { create(:simple_order_cycle, coordinator: shop, orders_open_at: 1.minute.ago, orders_close_at: 10.minutes.from_now) }
    let(:order_cycle2) { create(:simple_order_cycle, coordinator: shop, orders_open_at: 10.minutes.ago, orders_close_at: 1.minute.ago) }
    let(:schedule) { create(:schedule, order_cycles: [order_cycle1, order_cycle2]) }
    let(:standing_order) { create(:standing_order, shop: shop, schedule: schedule) }
    let!(:proxy_order) { create(:proxy_order, standing_order: standing_order, order_cycle: order_cycle1) } # OK

    it "ignores proxy orders where the OC has closed" do
      expect(job.send(:proxy_orders)).to include proxy_order
      proxy_order.update_attributes!(order_cycle_id: order_cycle2.id)
      expect(job.send(:proxy_orders)).to_not include proxy_order
    end

    it "ignores proxy orders for paused or cancelled standing orders" do
      expect(job.send(:proxy_orders)).to include proxy_order
      standing_order.update_attributes!(paused_at: 1.minute.ago)
      expect(job.send(:proxy_orders)).to_not include proxy_order
      standing_order.update_attributes!(paused_at: nil)
      expect(job.send(:proxy_orders)).to include proxy_order
      standing_order.update_attributes!(canceled_at: 1.minute.ago)
      expect(job.send(:proxy_orders)).to_not include proxy_order
    end

    it "ignores proxy orders that have been marked as cancelled or placed" do
      expect(job.send(:proxy_orders)).to include proxy_order
      proxy_order.update_attributes!(canceled_at: 5.minutes.ago)
      expect(job.send(:proxy_orders)).to_not include proxy_order
      proxy_order.update_attributes!(canceled_at: nil)
      expect(job.send(:proxy_orders)).to include proxy_order
      proxy_order.update_attributes!(placed_at: 5.minutes.ago)
      expect(job.send(:proxy_orders)).to_not include proxy_order
    end
  end

  describe "performing the job" do
    context "when unplaced proxy_orders exist" do
      let!(:proxy_order) { create(:proxy_order) }

      before do
        allow(job).to receive(:proxy_orders) { ProxyOrder.where(id: proxy_order.id) }
        allow(job).to receive(:process)
      end

      it "marks placeable proxy_orders as processed by setting placed_at" do
        expect{job.perform}.to change{proxy_order.reload.placed_at}
        expect(proxy_order.placed_at).to be_within(5.seconds).of Time.now
      end

      it "processes placeable proxy_orders" do
        job.perform
        expect(job).to have_received(:process).with(proxy_order.reload.order)
      end
    end
  end

  describe "checking that line items are available to purchase" do
    let(:order_cycle) { create(:simple_order_cycle) }
    let(:shop) { order_cycle.coordinator }
    let(:order) { create(:order, order_cycle: order_cycle, distributor: shop) }
    let(:ex) { create(:exchange, :order_cycle => order_cycle, :sender => shop, :receiver => shop, :incoming => false) }
    let(:variant1) { create(:variant, count_on_hand: 5) }
    let(:variant2) { create(:variant, count_on_hand: 5) }
    let(:variant3) { create(:variant, count_on_hand: 5) }
    let!(:line_item1) { create(:line_item, order: order, variant: variant1, quantity: 3) }
    let!(:line_item2) { create(:line_item, order: order, variant: variant2, quantity: 3) }
    let!(:line_item3) { create(:line_item, order: order, variant: variant3, quantity: 3) }

    before { Spree::Config.set(:allow_backorders, false) }

    context "when all items are available from the order cycle" do
      before { [variant1, variant2, variant3].each { |v| ex.variants << v } }

      context "and insufficient stock exists to fulfil the order for some items" do
        before do
          variant1.update_attribute(:count_on_hand, 5)
          variant2.update_attribute(:count_on_hand, 2)
          variant3.update_attribute(:count_on_hand, 0)
        end

        it "caps quantity at the stock level for stock-limited items, and reports the change" do
          changes = job.send(:cap_quantity_and_store_changes, order.reload)
          expect(line_item1.reload.quantity).to be 3 # not capped
          expect(line_item2.reload.quantity).to be 2 # capped
          expect(line_item3.reload.quantity).to be 0 # capped
          expect(changes[line_item1.id]).to be nil
          expect(changes[line_item2.id]).to be 3
          expect(changes[line_item3.id]).to be 3
        end
      end
    end

    context "and some items are not available from the order cycle" do
      before { [variant2, variant3].each { |v| ex.variants << v } }

      context "and insufficient stock exists to fulfil the order for some items" do
        before do
          variant1.update_attribute(:count_on_hand, 5)
          variant2.update_attribute(:count_on_hand, 2)
          variant3.update_attribute(:count_on_hand, 0)
        end

        it "sets quantity to 0 for unavailable items, and reports the change" do
          changes = job.send(:cap_quantity_and_store_changes, order.reload)
          expect(line_item1.reload.quantity).to be 0 # unavailable
          expect(line_item2.reload.quantity).to be 2 # capped
          expect(line_item3.reload.quantity).to be 0 # capped
          expect(changes[line_item1.id]).to be 3
          expect(changes[line_item2.id]).to be 3
          expect(changes[line_item3.id]).to be 3
        end
      end
    end
  end

  describe "processing a standing order order" do
    let(:standing_order) { create(:standing_order, with_items: true) }
    let(:proxy_order) { create(:proxy_order, standing_order: standing_order) }
    let!(:order) { proxy_order.initialise_order! }

    before do
      expect_any_instance_of(Spree::Payment).to_not receive(:process!)
      allow(job).to receive(:send_placement_email)
      allow(job).to receive(:send_empty_email)
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
      context "when no stock items are available after capping stock" do
        before do
          allow(job).to receive(:unavailable_stock_lines_for) { order.line_items }
        end

        it "does not place the order, sends an empty_order email" do
          expect{job.send(:process, order)}.to_not change{order.reload.completed_at}.from(nil)
          expect(job).to_not have_received(:send_placement_email)
          expect(job).to have_received(:send_empty_email)
        end
      end

      context "when at least one stock item is available after capping stock" do
        it "processes the order to completion, but does not process the payment" do
          # If this spec starts complaining about no shipping methods being available
          # on CI, there is probably another spec resetting the currency though Rails.cache.clear
          expect{job.send(:process, order)}.to change{order.reload.completed_at}.from(nil)
          expect(order.completed_at).to be_within(5.seconds).of Time.now
          expect(order.payments.first.state).to eq "checkout"
        end

        it "does not enqueue confirmation emails" do
          expect{job.send(:process, order)}.to_not enqueue_job ConfirmOrderJob
          expect(job).to have_received(:send_placement_email).with(order, anything).once
        end

        context "when progression of the order fails" do
          before { allow(order).to receive(:next) { false } }

          it "logs an error" do
            expect(Rails.logger).to receive(:info)
            job.send(:process, order)
          end
        end
      end
    end
  end

  describe "sending placement email" do
    let(:standing_order) { create(:standing_order, with_items: true) }
    let(:proxy_order) { create(:proxy_order, standing_order: standing_order) }
    let!(:order) { proxy_order.initialise_order! }
    let(:mail_mock) { double(:mailer_mock) }
    let(:changes) { double(:changes) }

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
