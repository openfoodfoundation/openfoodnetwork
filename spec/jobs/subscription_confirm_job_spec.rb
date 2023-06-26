# frozen_string_literal: true

require 'spec_helper'

describe SubscriptionConfirmJob do
  let(:job) { SubscriptionConfirmJob.new }

  describe "finding proxy_orders that are ready to be confirmed" do
    let(:shop) { create(:distributor_enterprise) }
    let(:order_cycle1) {
      create(:simple_order_cycle, coordinator: shop, orders_close_at: 59.minutes.ago,
                                  updated_at: 1.day.ago)
    }
    let(:order_cycle2) {
      create(:simple_order_cycle, coordinator: shop, orders_close_at: 61.minutes.ago,
                                  updated_at: 1.day.ago)
    }
    let(:schedule) { create(:schedule, order_cycles: [order_cycle1, order_cycle2]) }
    let(:subscription) { create(:subscription, with_items: true, shop: shop, schedule: schedule) }
    let!(:proxy_order) do
      create(:proxy_order, subscription: subscription, order_cycle: order_cycle1,
                           placed_at: 5.minutes.ago)
    end
    let!(:order) { proxy_order.initialise_order! }
    let(:proxy_orders) { job.send(:unconfirmed_proxy_orders) }

    before do
      OrderWorkflow.new(order).complete!
    end

    it "returns proxy orders that meet all of the criteria" do
      expect(proxy_orders).to include proxy_order
    end

    it "returns proxy orders for paused subscriptions" do
      subscription.update!(paused_at: 1.minute.ago)
      expect(proxy_orders).to include proxy_order
    end

    it "returns proxy orders for cancelled subscriptions" do
      subscription.update!(canceled_at: 1.minute.ago)
      expect(proxy_orders).to include proxy_order
    end

    it "ignores proxy orders where the OC closed more than 1 hour ago" do
      proxy_order.update!(order_cycle_id: order_cycle2.id)
      expect(proxy_orders).to_not include proxy_order
    end

    it "ignores cancelled proxy orders" do
      proxy_order.update!(canceled_at: 5.minutes.ago)
      expect(proxy_orders).to_not include proxy_order
    end

    it "ignores proxy orders without a completed order" do
      proxy_order.order.completed_at = nil
      proxy_order.order.save!
      expect(proxy_orders).to_not include proxy_order
    end

    it "ignores proxy orders without an associated order" do
      proxy_order.update!(order_id: nil)
      expect(proxy_orders).to_not include proxy_order
    end

    it "ignores proxy orders that haven't been placed yet" do
      proxy_order.update!(placed_at: nil)
      expect(proxy_orders).to_not include proxy_order
    end

    it "ignores proxy orders that have already been confirmed" do
      proxy_order.update!(confirmed_at: 1.second.ago)
      expect(proxy_orders).to_not include proxy_order
    end

    it "ignores orders that have been cancelled" do
      proxy_order.order.cancel!
      expect(proxy_orders).to_not include proxy_order
    end
  end

  describe "performing the job" do
    context "when unconfirmed proxy_orders exist" do
      let!(:proxy_order) { create(:proxy_order) }

      before do
        proxy_order.initialise_order!
        allow(job).to receive(:unconfirmed_proxy_orders) { ProxyOrder.where(id: proxy_order.id) }
        allow(job).to receive(:confirm_order!)
        allow(job).to receive(:send_confirmation_summary_emails)
      end

      it "marks confirmable proxy_orders as processed by setting confirmed_at" do
        expect{ job.perform }.to change{ proxy_order.reload.confirmed_at }
        expect(proxy_order.confirmed_at).to be_within(5.seconds).of Time.zone.now
      end

      it "processes confirmable proxy_orders" do
        job.perform
        expect(job).to have_received(:confirm_order!).with(proxy_order.reload.order)
      end

      it "sends a summary email" do
        job.perform
        expect(job).to have_received(:send_confirmation_summary_emails)
      end
    end
  end

  describe "finding recently closed order cycles" do
    let!(:order_cycle1) {
      create(:simple_order_cycle, orders_close_at: 61.minutes.ago, updated_at: 61.minutes.ago)
    }
    let!(:order_cycle2) {
      create(:simple_order_cycle, orders_close_at: nil, updated_at: 59.minutes.ago)
    }
    let!(:order_cycle3) {
      create(:simple_order_cycle, orders_close_at: 61.minutes.ago, updated_at: 59.minutes.ago)
    }
    let!(:order_cycle4) {
      create(:simple_order_cycle, orders_close_at: 59.minutes.ago, updated_at: 61.minutes.ago)
    }
    let!(:order_cycle5) { create(:simple_order_cycle, orders_close_at: 1.minute.from_now) }

    it "returns closed order cycles whose orders_close_at " \
       "or updated_at date is within the last hour" do
      order_cycles = job.send(:recently_closed_order_cycles)
      expect(order_cycles).to include order_cycle3, order_cycle4
      expect(order_cycles).to_not include order_cycle1, order_cycle2, order_cycle5
    end
  end

  describe "confirming an order" do
    let(:shop) { create(:distributor_enterprise) }
    let(:order_cycle1) { create(:simple_order_cycle, coordinator: shop) }
    let(:order_cycle2) { create(:simple_order_cycle, coordinator: shop) }
    let(:schedule1) { create(:schedule, order_cycles: [order_cycle1, order_cycle2]) }
    let(:subscription1) { create(:subscription, shop: shop, schedule: schedule1, with_items: true) }
    let(:proxy_order) { create(:proxy_order, subscription: subscription1) }
    let(:order) { proxy_order.initialise_order! }

    before do
      OrderWorkflow.new(order).complete!
      allow(job).to receive(:send_confirmation_email).and_call_original
      allow(job).to receive(:send_payment_authorization_emails).and_call_original
      expect(job).to receive(:record_order)
    end

    context "when Stripe payments need to be processed" do
      let(:charge_response_mock) do
        { status: 200, body: JSON.generate(id: "ch_1234", object: "charge", amount: 2000) }
      end

      before do
        allow(order).to receive(:payment_required?) { true }
        expect(job).to receive(:setup_payment!) { true }
        stub_request(:post, "https://api.stripe.com/v1/charges")
          .with(body: /amount/)
          .to_return(charge_response_mock)
      end

      context "Stripe SCA" do
        let(:stripe_sca_payment_method) { create(:stripe_sca_payment_method) }
        let(:stripe_sca_payment) {
          create(:payment, amount: 10, payment_method: stripe_sca_payment_method)
        }
        let(:provider) { double }

        before do
          allow_any_instance_of(Stripe::CreditCardCloner).
            to receive(:find_or_clone) { ["cus_123", "pm_1234"] }
          allow(order).to receive(:pending_payments) { [stripe_sca_payment] }
          allow(stripe_sca_payment_method).to receive(:provider) { provider }
          allow(stripe_sca_payment_method.provider).to receive(:purchase) { true }
          allow(stripe_sca_payment_method.provider).to receive(:capture) { true }
        end

        it "runs the charges in offline mode" do
          job.send(:confirm_order!, order)
          expect(stripe_sca_payment_method.provider).to have_received(:purchase)
        end

        it "uses #capture if the payment is already authorized" do
          allow(stripe_sca_payment).to receive(:preauthorized?) { true }
          expect(stripe_sca_payment_method.provider).to receive(:capture)
          job.send(:confirm_order!, order)
        end

        it "authorizes the payment with Stripe" do
          allow(order)
            .to receive_message_chain(:subscription, :payment_method) { stripe_sca_payment_method }
          expect(OrderManagement::Order::StripeScaPaymentAuthorize).
            to receive_message_chain(:new, :call!) { true }

          job.send(:confirm_order!, order)
        end
      end
    end

    context "when payments need to be processed" do
      let(:payment_method) { create(:payment_method) }
      let(:payment) { create(:payment, amount: 10) }

      before do
        allow(order).to receive(:payment_required?) { true }
        allow(order).to receive(:pending_payments) { [payment] }
      end

      context "and an error is added to the order when updating payments" do
        before do
          expect(job).to receive(:setup_payment!) { |order|
                           order.errors.add(:base, "a payment error")
                         }
        end

        it "sends a failed payment email" do
          expect(job).to receive(:send_failed_payment_email)
          expect(job).to_not receive(:send_confirmation_email)
          job.send(:confirm_order!, order)
        end
      end

      context "and no errors are added when updating payments" do
        before { expect(job).to receive(:setup_payment!) { true } }

        context "when an error occurs while processing the payment" do
          before do
            expect(payment).to receive(:process_offline!).and_raise Spree::Core::GatewayError,
                                                                    "payment failure error"
          end

          it "sends a failed payment email" do
            expect(job).to receive(:send_failed_payment_email)
            expect(job).to_not receive(:send_confirmation_email)
            expect(job).to_not receive(:send_payment_authorization_emails)
            job.send(:confirm_order!, order)
          end
        end

        context "when payments are processed without error" do
          before do
            expect(payment).to receive(:process_offline!) { true }
            expect(payment).to receive(:completed?) { true }
          end

          it "sends only a subscription confirm email, no regular confirmation emails" do
            expect{ job.send(:confirm_order!, order) }
              .to_not have_enqueued_mail(Spree::OrderMailer, :confirm_email_for_customer)

            expect(job).to have_received(:send_confirmation_email).once
          end
        end
      end
    end
  end

  describe "#send_confirmation_email" do
    let(:order) { instance_double(Spree::Order) }
    let(:mail_mock) { double(:mailer_mock, deliver_now: true) }

    before do
      allow(SubscriptionMailer).to receive(:confirmation_email) { mail_mock }
    end

    it "records a success and sends the email" do
      expect(order).to receive(:update_order!)
      expect(job).to receive(:record_success).with(order).once
      job.send(:send_confirmation_email, order)
      expect(SubscriptionMailer).to have_received(:confirmation_email).with(order)
      expect(mail_mock).to have_received(:deliver_now)
    end
  end

  describe "#send_failed_payment_email" do
    let(:order) { instance_double(Spree::Order) }
    let(:mail_mock) { double(:mailer_mock, deliver_now: true) }

    before do
      allow(SubscriptionMailer).to receive(:failed_payment_email) { mail_mock }
    end

    it "records and logs an error and sends the email" do
      expect(order).to receive(:update_order!)
      expect(job).to receive(:record_and_log_error).with(:failed_payment, order, nil).once
      job.send(:send_failed_payment_email, order)
      expect(SubscriptionMailer).to have_received(:failed_payment_email).with(order)
      expect(mail_mock).to have_received(:deliver_now)
    end
  end
end
