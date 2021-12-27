# frozen_string_literal: true

require 'spec_helper'

module PaymentGateways
  describe StripeController, type: :controller do
    include StripeStubs

    let!(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
    let!(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }
    let!(:order) { create(:order_with_totals, distributor: distributor, order_cycle: order_cycle) }
    let(:exchange) { order_cycle.exchanges.to_enterprises(distributor).outgoing.first }

    let(:order_cycle_distributed_variants) { instance_double(OrderCycleDistributedVariants) }

    before do
      exchange.variants << order.line_items.first.variant
      allow(controller).to receive(:current_order).and_return(order)
    end

    describe "#confirm" do
      context "when the order is in payment state and a stripe payment intent is provided" do
        let(:user) { order.user }
        let(:payment_method) { create(:stripe_sca_payment_method) }
        let(:payment) {
          create(
            :payment,
            amount: order.total,
            state: "requires_authorization",
            payment_method: payment_method,
            response_code: "pi_123"
          )
        }

        before do
          Stripe.api_key = "sk_test_12345"
          stub_payment_intent_get_request
          stub_successful_capture_request(order: order)

          allow(controller).to receive(:spree_current_user).and_return(user)
          user.bill_address = create(:address)
          user.ship_address = create(:address)
          user.save!

          order.update_attribute :state, "payment"
          order.payments << payment
        end

        it "completes the order and redirects to the order confirmation page" do
          expect(controller).to receive(:processing_succeeded).and_call_original
          expect(controller).to receive(:order_completion_reset).and_call_original

          get :confirm, params: { payment_intent: "pi_123" }

          expect(order.completed?).to be true
          expect(response).to redirect_to order_path(order, order_token: order.token)
          expect(flash[:notice]).to eq I18n.t(:order_processed_successfully)
        end

        it "creates a customer record" do
          order.update_columns(customer_id: nil)
          Customer.delete_all

          expect {
            get :confirm, params: { payment_intent: "pi_123" }
          }.to change { Customer.count }.by(1)
        end
      end

      context "when the order is not in payment state" do
        before { order.update_columns(state: "cart", completed_at: nil) }

        it "fails" do
          expect(controller).to receive(:processing_failed).and_call_original

          get :confirm, params: { payment_intent: "pi_123" }

          expect(order.completed?).to be false
          expect(response).to redirect_to checkout_path
          expect(flash[:error]).to eq I18n.t(:payment_processing_failed)
        end
      end

      context "when a valid payment intent is not provided" do
        it "fails" do
          expect(controller).to receive(:processing_failed).and_call_original

          get :confirm, params: { payment_intent: "pi_666" }

          expect(order.completed?).to be false
          expect(response).to redirect_to checkout_path
          expect(flash[:error]).to eq I18n.t(:payment_processing_failed)
        end
      end

      context "when items in the cart are invalid" do
        before do
          allow(order_cycle_distributed_variants).
            to receive(:distributes_order_variants?).and_return(false)
        end

        it "fails" do
          expect(controller).to receive(:processing_failed).and_call_original

          get :confirm, params: { payment_intent: "pi_123" }

          expect(order.completed?).to be false
          expect(response).to redirect_to checkout_path
          expect(flash[:error]).to eq I18n.t(:payment_processing_failed)
        end
      end

      context "items running out of stock during order completion" do
        it "redirects to cart when some items are out of stock" do
          allow(controller).to receive(:valid_payment_intent?).and_return true
          allow(order).to receive_message_chain(:insufficient_stock_lines, :empty?).and_return false

          get :confirm, params: { payment_intent: "pi_123" }
          expect(response).to redirect_to cart_path
        end

        context "handling pending payments" do
          let!(:payment) { create(:payment, state: "pending", amount: order.total, order: order) }
          let!(:transaction_fee) {
            create(:adjustment, state: "open", amount: 10, order: order, adjustable: payment)
          }

          before do
            allow(order).to receive_message_chain(:insufficient_stock_lines, :empty?) { false }
            order.save
            allow(order).to receive_message_chain(:payments, :completed) { [] }
            allow(order).to receive_message_chain(:payments, :incomplete) { [payment] }
            allow(controller).to receive(:valid_payment_intent?) { true }
            allow(controller).to receive(:last_payment) { payment }
            allow(payment).to receive(:adjustment) { transaction_fee }
          end

          it "cancels the payment and resets the order to cart" do
            expect(payment).to receive(:void_transaction!).and_call_original

            get :confirm, params: { payment_intent: "pi_123" }

            expect(response).to redirect_to cart_path
            expect(flash[:notice]).to eq I18n.t('checkout.payment_cancelled_due_to_stock')

            expect(order.state).to eq "cart"
            expect(payment.state).to eq "void"
            expect(transaction_fee.reload.eligible).to eq false
            expect(transaction_fee.state).to eq "finalized"
          end
        end
      end
    end
  end
end
