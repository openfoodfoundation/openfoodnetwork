# frozen_string_literal: true

require 'spec_helper'

describe SubscriptionPlacementJob do
  let(:job) { SubscriptionPlacementJob.new }

  describe "finding proxy_orders that are ready to be placed" do
    let(:shop) { create(:distributor_enterprise) }
    let(:order_cycle1) {
      create(:simple_order_cycle, coordinator: shop, orders_open_at: 1.minute.ago,
                                  orders_close_at: 10.minutes.from_now)
    }
    let(:order_cycle2) {
      create(:simple_order_cycle, coordinator: shop, orders_open_at: 10.minutes.ago,
                                  orders_close_at: 1.minute.ago)
    }
    let(:schedule) { create(:schedule, order_cycles: [order_cycle1, order_cycle2]) }
    let(:subscription) { create(:subscription, shop: shop, schedule: schedule) }
    let!(:proxy_order) {
      create(:proxy_order, subscription: subscription, order_cycle: order_cycle1)
    } # OK

    it "ignores proxy orders where the OC has closed" do
      expect(job.send(:proxy_orders)).to include proxy_order
      proxy_order.update!(order_cycle_id: order_cycle2.id)
      expect(job.send(:proxy_orders)).to_not include proxy_order
    end

    it "ignores proxy orders for paused or cancelled subscriptions" do
      expect(job.send(:proxy_orders)).to include proxy_order
      subscription.update!(paused_at: 1.minute.ago)
      expect(job.send(:proxy_orders)).to_not include proxy_order
      subscription.update!(paused_at: nil)
      expect(job.send(:proxy_orders)).to include proxy_order
      subscription.update!(canceled_at: 1.minute.ago)
      expect(job.send(:proxy_orders)).to_not include proxy_order
    end

    it "ignores proxy orders that have been marked as cancelled or placed" do
      expect(job.send(:proxy_orders)).to include proxy_order
      proxy_order.update!(canceled_at: 5.minutes.ago)
      expect(job.send(:proxy_orders)).to_not include proxy_order
      proxy_order.update!(canceled_at: nil)
      expect(job.send(:proxy_orders)).to include proxy_order
      proxy_order.update!(placed_at: 5.minutes.ago)
      expect(job.send(:proxy_orders)).to_not include proxy_order
    end
  end

  describe "performing the job" do
    context "when unplaced proxy_orders exist" do
      let!(:subscription) { create(:subscription, with_items: true) }
      let(:order) { build(:order, distributor: create(:enterprise)) }
      let!(:proxy_order) { create(:proxy_order, subscription: subscription, order: order) }

      before do
        allow(job).to receive(:proxy_orders) { ProxyOrder.where(id: proxy_order.id) }
      end

      it "processes placeable proxy_orders" do
        summarizer = instance_double(OrderManagement::Subscriptions::Summarizer)
        service = PlaceProxyOrder.new(
          proxy_order,
          summarizer,
          JobLogger.logger,
          CapQuantity.new(proxy_order.order)
        )

        allow(PlaceProxyOrder).to receive(:new) { service }
        allow(service).to receive(:call)

        job.perform

        expect(service).to have_received(:call)
      end

      it "records exceptions" do
        order.line_items << build(:line_item)

        summarizer = TestSummarizer.new
        allow(OrderManagement::Subscriptions::Summarizer).to receive(:new).and_return(summarizer)

        job.perform

        expect(summarizer.recorded_issues[order.id])
          .to eq("Errors: Cannot transition state via :next from :address (Reason(s): Items cannot be shipped)")
      end
    end
  end

  describe "processing a subscription order" do
    let!(:shipping_method_created_earlier) { create(:shipping_method, distributors: [shop]) }
    let!(:shipping_method) { create(:shipping_method, distributors: [shop]) }
    let!(:shipping_method_created_later) { create(:shipping_method, distributors: [shop]) }

    let(:shop) { create(:enterprise) }
    let(:subscription) { create(:subscription, shop: shop, with_items: true) }
    let(:proxy_order) { create(:proxy_order, subscription: subscription) }
    let(:oc) { proxy_order.order_cycle }
    let(:ex) { oc.exchanges.outgoing.find_by(sender_id: shop.id, receiver_id: shop.id) }
    let(:fee) { create(:enterprise_fee, enterprise: shop, fee_type: 'sales', amount: 10) }
    let!(:exchange_fee) { ExchangeFee.create!(exchange: ex, enterprise_fee: fee) }

    before do
      expect_any_instance_of(Spree::Payment).to_not receive(:process!)
      allow_any_instance_of(PlaceProxyOrder).to receive(:send_placement_email)
      allow_any_instance_of(PlaceProxyOrder).to receive(:send_empty_email)
    end

    context "when the order is not already complete" do
      context "when no stock items are available after capping stock" do
        let(:store_changes) { CapQuantity.new(order) }

        before do
          allow(store_changes).to receive(:unavailable_stock_lines_for) { order.line_items }
        end

        it "does not place the order, clears all adjustments, and sends an empty_order email" do
          summarizer = instance_double(OrderManagement::Subscriptions::Summarizer, record_order: true, record_issue: true)
          service = PlaceProxyOrder.new(
            proxy_order,
            summarizer,
            JobLogger.logger,
            store_changes
          )

          allow(service).to receive(:send_placement_email)
          allow(service).to receive(:send_empty_email)

          expect { service.call }.to_not change { order.reload.completed_at }.from(nil)
          expect(order.all_adjustments).to be_empty
          expect(order.total).to eq 0
          expect(order.adjustment_total).to eq 0
          expect(service).to_not have_received(:send_placement_email)
          expect(service).to have_received(:send_empty_email)
        end
      end

      context "when at least one stock item is available after capping stock" do
        let(:summarizer) do
          instance_double(OrderManagement::Subscriptions::Summarizer, record_order: true, record_success: true)
        end
        let(:service) do
          PlaceProxyOrder.new(
            proxy_order,
            summarizer,
            JobLogger.logger,
            CapQuantity.new(order)
          )
        end

        before do
          allow(service).to receive(:send_placement_email)
        end

        it "processes the order to completion, but does not process the payment" do
          # If this spec starts complaining about no shipping methods being available
          # on CI, there is probably another spec resetting the currency though Rails.cache.clear
          expect{ service.call }.to change{ order.reload.completed_at }.from(nil)
          expect(order.completed_at).to be_within(5.seconds).of Time.zone.now
          expect(order.payments.first.state).to eq "checkout"
        end

        it "does not enqueue confirmation emails" do
          expect{ service.call }
            .to_not have_enqueued_mail(Spree::OrderMailer, :confirm_email_for_customer)

          expect(service).to have_received(:send_placement_email).once
        end

        context "when progression of the order fails" do
          before { allow(service).to receive(:move_to_completion).and_raise(StandardError) }

          it "records an error and does not attempt to send an email" do
            expect(service).to_not receive(:send_placement_email)
            expect(summarizer).to receive(:record_and_log_error).once
            service.call
          end
        end
      end
    end

    context "when the proxy order fails to generate an order" do
      before do
        allow(proxy_order).to receive(:order) { nil }
      end

      it "records an error " do
        expect_any_instance_of(OrderManagement::Subscriptions::Summarizer).to receive(:record_subscription_issue)
        expect(job).to_not receive(:place_order)
        job.send(:place_order_for, proxy_order)
      end
    end
  end
end
