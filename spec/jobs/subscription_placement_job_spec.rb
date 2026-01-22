# frozen_string_literal: true

RSpec.describe SubscriptionPlacementJob do
  let(:job) { SubscriptionPlacementJob.new }
  let(:summarizer) { OrderManagement::Subscriptions::Summarizer.new }

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
    let(:subscription) { create(:subscription, shop:, schedule:) }
    let!(:proxy_order) {
      create(:proxy_order, subscription:, order_cycle: order_cycle1)
    } # OK

    it "ignores proxy orders where the OC has closed" do
      expect(job.__send__(:proxy_orders)).to include proxy_order
      proxy_order.update!(order_cycle_id: order_cycle2.id)
      expect(job.__send__(:proxy_orders)).not_to include proxy_order
    end

    it "ignores proxy orders for paused or cancelled subscriptions" do
      expect(job.__send__(:proxy_orders)).to include proxy_order
      subscription.update!(paused_at: 1.minute.ago)
      expect(job.__send__(:proxy_orders)).not_to include proxy_order
      subscription.update!(paused_at: nil)
      expect(job.__send__(:proxy_orders)).to include proxy_order
      subscription.update!(canceled_at: 1.minute.ago)
      expect(job.__send__(:proxy_orders)).not_to include proxy_order
    end

    it "ignores proxy orders that have been marked as cancelled or placed" do
      expect(job.__send__(:proxy_orders)).to include proxy_order
      proxy_order.update!(canceled_at: 5.minutes.ago)
      expect(job.__send__(:proxy_orders)).not_to include proxy_order
      proxy_order.update!(canceled_at: nil)
      expect(job.__send__(:proxy_orders)).to include proxy_order
      proxy_order.update!(placed_at: 5.minutes.ago)
      expect(job.__send__(:proxy_orders)).not_to include proxy_order
    end
  end

  describe "performing the job" do
    context "when unplaced proxy_orders exist" do
      let!(:subscription) { create(:subscription, with_items: true) }
      let(:order) { build(:order, distributor: shop, line_items: [build(:line_item)]) }
      let(:shop) { order_cycle.coordinator }
      let(:order_cycle) { create(:simple_order_cycle) }
      let(:exchange) {
        create(:exchange, order_cycle:, sender: shop, receiver: shop, incoming: false)
      }
      let!(:proxy_order) {
        create(:proxy_order, subscription:, order_cycle:, order:)
      }

      before do
        allow(job).to receive(:proxy_orders) { ProxyOrder.where(id: proxy_order.id) }
      end

      it "processes placeable proxy_orders" do
        service = PlaceProxyOrder.new(proxy_order, summarizer, JobLogger.logger, CapQuantity.new)

        allow(PlaceProxyOrder).to receive(:new) { service }
        allow(service).to receive(:call)

        job.perform

        expect(service).to have_received(:call)
      end

      it "records exceptions" do
        exchange.variants << order.line_items.first.variant

        summarizer = TestSummarizer.new
        allow(OrderManagement::Subscriptions::Summarizer).to receive(:new).and_return(summarizer)

        job.perform

        expect(summarizer.recorded_issues[order.id])
          .to eq("Errors: Cannot transition state via :next from :address " \
                 "(Reason(s): Items cannot be shipped)")
      end
    end
  end

  describe "processing a subscription order" do
    let!(:shipping_method_created_earlier) { create(:shipping_method, distributors: [shop]) }
    let!(:shipping_method) { create(:shipping_method, distributors: [shop]) }
    let!(:shipping_method_created_later) { create(:shipping_method, distributors: [shop]) }

    let(:shop) { create(:enterprise) }
    let(:subscription) { create(:subscription, shop:, with_items: true) }
    let(:proxy_order) { create(:proxy_order, subscription:) }
    let(:oc) { proxy_order.order_cycle }
    let(:ex) { oc.exchanges.outgoing.find_by(sender_id: shop.id, receiver_id: shop.id) }
    let(:fee) { create(:enterprise_fee, enterprise: shop, fee_type: 'sales', amount: 10) }
    let!(:exchange_fee) { ExchangeFee.create!(exchange: ex, enterprise_fee: fee) }

    before do
      expect_any_instance_of(Spree::Payment).not_to receive(:process!)
      allow_any_instance_of(PlaceProxyOrder).to receive(:send_placement_email)
      allow_any_instance_of(PlaceProxyOrder).to receive(:send_empty_email)
    end

    context "when the order is not already complete" do
      context "when no stock items are available after capping stock" do
        let(:service) do
          PlaceProxyOrder.new(proxy_order, summarizer, JobLogger.logger, store_updater)
        end
        let(:store_updater) { CapQuantity.new }

        before do
          fake_relation = instance_double(ActiveRecord::Relation, select: -123)
          allow(store_updater).to receive(:available_variants_for).and_return(fake_relation)
        end

        it "does not place the order, clears all adjustments, and sends an empty_order email" do
          allow(service).to receive(:send_placement_email)
          allow(service).to receive(:send_empty_email)

          service.call

          expect(proxy_order.order.reload.completed_at).to be_nil
          expect(proxy_order.order.all_adjustments).to be_empty
          expect(proxy_order.order.total).to eq 0
          expect(proxy_order.order.adjustment_total).to eq 0

          expect(service).not_to have_received(:send_placement_email)
          expect(service).to have_received(:send_empty_email)
        end
      end

      context "when at least one stock item is available after capping stock" do
        let(:service) do
          PlaceProxyOrder.new(proxy_order, summarizer, JobLogger.logger, CapQuantity.new)
        end

        before do
          allow(service).to receive(:send_placement_email)
        end

        it "processes the order to completion, but does not process the payment" do
          freeze_time do
            service.call
            proxy_order.order.reload.completed_at

            expect(proxy_order.order.completed_at).to eq(Time.zone.now)
            expect(proxy_order.order.payments.first.state).to eq "checkout"
          end
        end

        it "does not enqueue confirmation emails" do
          expect{ service.call }
            .not_to have_enqueued_mail(Spree::OrderMailer, :confirm_email_for_customer)

          expect(service).to have_received(:send_placement_email).once
        end

        context "when progression of the order fails" do
          before { allow(service).to receive(:move_to_completion).and_raise(StandardError) }

          it "records an error and does not attempt to send an email" do
            expect(service).not_to receive(:send_placement_email)
            expect(summarizer).to receive(:record_and_log_error).once
            service.call
          end
        end
      end
    end
  end

  describe "parallisation", concurrency: true do
    let(:shop) { create(:distributor_enterprise) }
    let(:order_cycle) {
      create(
        :simple_order_cycle,
        coordinator: shop,
        orders_open_at: 1.minute.ago,
        orders_close_at: 10.minutes.from_now
      )
    }
    let(:schedule) { create(:schedule, order_cycles: [order_cycle]) }
    let(:subscription) { create(:subscription, shop:, schedule:) }
    let!(:proxy_order) {
      create(:proxy_order, subscription:, order_cycle:)
    }
    let(:breakpoint) { Mutex.new }

    it "doesn't place duplicate orders" do
      # Pause jobs when placing proxy order:
      breakpoint.lock
      allow(PlaceProxyOrder).to(
        receive(:new).and_wrap_original do |method, *args|
          breakpoint.synchronize { nil }
          method.call(*args)
        end
      )

      expect {
        # Start two jobs in parallel:
        threads = [
          Thread.new { SubscriptionPlacementJob.new.perform },
          Thread.new { SubscriptionPlacementJob.new.perform },
        ]

        # Wait for both to jobs to pause.
        # This can reveal a race condition.
        sleep 1

        # Resume and complete both jobs:
        breakpoint.unlock
        threads.each(&:join)
      }.to change {
        Spree::Order.count
      }.by(1)
    end
  end
end
