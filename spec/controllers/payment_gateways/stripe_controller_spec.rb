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
          order.update_attribute :state, "confirmation"
        end

        it "creates a customer record" do
          order.update_columns(customer_id: nil)
          Customer.delete_all

          expect {
            get :confirm, params: { payment_intent: "pi_123" }
          }.to change { Customer.count }.by(1)
        end

        context "when the order cycle has closed" do
          it "redirects to shopfront with message if order cycle is expired" do
            allow(controller).to receive(:current_distributor).and_return(distributor)
            expect(controller).to receive(:current_order_cycle).and_return(order_cycle)
            expect(controller).to receive(:current_order).and_return(order).at_least(:once)
            expect(order_cycle).to receive(:closed?).and_return(true)
            expect(order).to receive(:empty!)
            expect(order).to receive(:set_order_cycle!).with(nil)

            get :confirm, params: { payment_intent: "pi_123" }

            expect(response).to redirect_to shop_url
            expect(flash[:info]).to eq "The order cycle you've selected has just closed. \
Please try again!"
          end
        end

        it "completes the order and redirects to the order confirmation page" do
          expect(controller).to receive(:processing_succeeded).and_call_original
          expect(controller).to receive(:order_completion_reset).and_call_original

          get :confirm, params: { payment_intent: "pi_123" }

          expect(order.completed?).to be true
          expect(response).to redirect_to order_path(order, order_token: order.token)
          expect(flash[:notice]).to eq 'Your order has been processed successfully'
        end

        context 'when order completion fails' do
          it "redirects to checkout state path" do
            expect(controller).to receive(:process_payment_completion!).and_call_original
            allow(order).to receive(:process_payments!).and_return(false)
            expect(
              get(:confirm, params: { payment_intent: "pi_123" })
            ).to redirect_to checkout_step_path(step: :payment)

            expect(flash[:error]).to eq(
              'Payment could not be processed, please check the details you entered'
            )
          end
        end
      end

      context "when the order is not in payment state" do
        before { order.update_columns(state: "cart", completed_at: nil) }

        it "fails" do
          expect(controller).to receive(:processing_failed).and_call_original

          get :confirm, params: { payment_intent: "pi_123" }

          expect(order.completed?).to be false
          expect(response).to redirect_to checkout_step_path(step: :details)
          expect(flash[:error]).to eq "Payment could not be processed, \
please check the details you entered"
        end
      end

      context "when a valid payment intent is not provided" do
        it "fails" do
          expect(controller).to receive(:processing_failed).and_call_original

          get :confirm, params: { payment_intent: "pi_666" }

          expect(order.completed?).to be false
          expect(response).to redirect_to checkout_step_path(step: :details)
          expect(flash[:error]).to eq "Payment could not be processed, \
please check the details you entered"
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
          expect(response).to redirect_to checkout_step_path(step: :details)
          expect(flash[:error]).to eq "Payment could not be processed, \
please check the details you entered"
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
            expect(flash[:notice]).to eq "Payment cancelled: the checkout could not be \
completed due to stock issues."

            expect(order.state).to eq "cart"
            expect(payment.state).to eq "void"
            expect(transaction_fee.reload.eligible).to eq false
            expect(transaction_fee.state).to eq "finalized"
          end
        end
      end
    end

    describe "#authorize" do
      let(:customer) { create(:customer) }
      let(:order) {
        create(:order_with_totals, customer: customer, distributor: customer.enterprise,
                                   state: "payment")
      }
      let(:payment_method) { create(:stripe_sca_payment_method) }
      let!(:payment) {
        create(
          :payment,
          payment_method: payment_method,
          cvv_response_message: "https://stripe.com/redirect",
          response_code: "pi_123",
          order: order,
          state: "requires_authorization"
        )
      }

      before do
        allow(controller).to receive(:spree_current_user) { current_user }
      end

      context "after returning from Stripe to authorize a payment" do
        let(:current_user) { order.user }

        context "with a valid payment intent" do
          let(:payment_intent) { "pi_123" }
          let(:payment_intent_response) { double(id: "pi_123", status: "requires_capture") }

          before do
            allow(Stripe::PaymentIntentValidator)
              .to receive_message_chain(:new, :call).and_return(payment_intent_response)

            allow(Spree::Order).to receive(:find_by) { order }
          end

          context "when the order is in payment state" do
            it "completes the payment" do
              expect(order).to receive(:process_payments!) do
                payment.complete!
              end

              get :authorize, params: { order_number: order.number, payment_intent: payment_intent }

              expect(response).to redirect_to order_path(order)
              payment.reload
              expect(payment.state).to eq("completed")
              expect(payment.cvv_response_message).to be nil
            end

            it "moves the order state to completed" do
              expect(order).to receive(:process_payments!) do
                payment.complete!
              end

              get :authorize, params: { order_number: order.number, payment_intent: payment_intent }

              expect(order.reload.state).to eq "complete"
            end
          end

          context "when the order is already completed" do
            before do
              order.update_columns(state: "complete")
            end

            it "should still process the payment" do
              expect(order).to receive(:process_payments!) do
                payment.complete!
              end

              get :authorize, params: { order_number: order.number, payment_intent: payment_intent }

              expect(response).to redirect_to order_path(order)
              payment.reload
              expect(payment.state).to eq("completed")
              expect(payment.cvv_response_message).to be nil
            end
          end

          context "when the order cycle has closed" do
            it "should still authorize the payment successfully" do
              expect(order).to receive(:process_payments!) do
                payment.complete!
              end

              get :authorize, params: { order_number: order.number, payment_intent: payment_intent }

              expect(response).to redirect_to order_path(order)
              payment.reload
              expect(payment.state).to eq("completed")
              expect(payment.cvv_response_message).to be nil
            end
          end
        end

        context "when the payment intent response has errors" do
          let(:payment_intent) { "pi_123" }

          before do
            allow(Stripe::PaymentIntentValidator)
              .to receive_message_chain(:new, :call).and_raise(Stripe::StripeError, "error message")
          end

          it "does not complete the payment" do
            get :authorize, params: { order_number: order.number, payment_intent: payment_intent }

            expect(response).to redirect_to order_path(order)
            expect(flash[:error]).to eq("The payment could not be processed. error message")
            payment.reload
            expect(payment.cvv_response_message).to be nil
            expect(payment.state).to eq("failed")
          end
        end

        context "with an invalid last payment" do
          let(:payment_intent) { "valid" }
          let(:finder) { instance_double(OrderPaymentFinder, last_payment: payment) }

          before do
            allow(payment).to receive(:response_code).and_return("invalid")
            allow(OrderPaymentFinder).to receive(:new).with(order).and_return(finder)
            allow(Stripe::PaymentIntentValidator)
              .to receive_message_chain(:new, :call).and_return(payment_intent)
            stub_payment_intent_get_request(payment_intent_id: "valid")
          end

          it "does not complete the payment" do
            get :authorize, params: { order_number: order.number, payment_intent: payment_intent }

            expect(response).to redirect_to order_path(order)
            expect(flash[:error]).to eq("The payment could not be processed. ")
            payment.reload
            expect(payment.cvv_response_message).to eq("https://stripe.com/redirect")
            expect(payment.state).to eq("requires_authorization")
          end
        end
      end
    end
  end
end
