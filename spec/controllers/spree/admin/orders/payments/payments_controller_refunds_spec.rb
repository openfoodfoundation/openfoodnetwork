# frozen_string_literal: true

require 'spec_helper'

describe Spree::Admin::PaymentsController, type: :controller do
  include StripeHelper
  include StripeStubs

  let!(:shop) { create(:enterprise) }
  let!(:user) { shop.owner }
  let!(:order) { create(:completed_order_with_totals, distributor: shop) }
  let!(:line_item) { create(:line_item, order: order, price: 5.0) }

  before do
    allow(controller).to receive(:spree_current_user) { user }
    order.reload.update_totals
  end

  context "StripeSCA" do
    context "voiding a payment" do
      let(:params) { { id: payment.id, order_id: order.number, e: :void } }

      # Required for the respond override in the controller decorator to work
      before { @request.env['HTTP_REFERER'] = spree.admin_order_payments_url(payment) }

      context "that was processed by stripe" do
        let!(:payment_method) { create(:stripe_sca_payment_method, distributors: [shop]) }
        let!(:payment) do
          create(:payment, :completed, order: order, payment_method: payment_method,
                                       response_code: 'pi_123', amount: order.total)
        end
        let(:stripe_account) { create(:stripe_account, enterprise: shop) }

        before do
          Stripe.api_key = "sk_test_12345"
          allow(StripeAccount).to receive(:find_by) { stripe_account }
        end

        context "when the payment has been confirmed" do
          context "where the request succeeds" do
            before do
              stub_payment_intent_get_request(response: { intent_status: "succeeded" })
              # Issues the refund
              stub_request(:post, "https://api.stripe.com/v1/charges/ch_1234/refunds").
                with(basic_auth: ["sk_test_12345", ""]).
                to_return(status: 200,
                          body: JSON.generate(id: 're_123', object: 'refund', status: 'succeeded') )
            end

            it "voids the payment" do
              order.reload
              expect(order.payment_total).to_not eq 0
              expect(order.outstanding_balance.to_f).to eq 0
              spree_put :fire, params
              expect(payment.reload.state).to eq 'void'
              order.reload
              expect(order.payment_total).to eq 0
              expect(order.outstanding_balance.to_f).to_not eq 0
            end
          end

          context "where the request fails" do
            before do
              stub_payment_intent_get_request(response: { intent_status: "succeeded" })
              stub_request(:post, "https://api.stripe.com/v1/charges/ch_1234/refunds").
                with(basic_auth: ["sk_test_12345", ""]).
                to_return(status: 200, body: JSON.generate(error: { message: "Bup-bow!" }) )
            end

            it "does not void the payment" do
              order.reload
              expect(order.payment_total).to_not eq 0
              expect(order.outstanding_balance.to_f).to eq 0
              spree_put :fire, params
              expect(payment.reload.state).to eq 'completed'
              order.reload
              expect(order.payment_total).to_not eq 0
              expect(order.outstanding_balance.to_f).to eq 0
              expect(flash[:error]).to eq "Bup-bow!"
            end
          end

          context "when a partial refund has already been issued" do
            before do
              stub_payment_intent_get_request(response: { intent_status: "succeeded",
                                                          amount_refunded: 200 })
              stub_request(:post, "https://api.stripe.com/v1/charges/ch_1234/refunds").
                with(basic_auth: ["sk_test_12345", ""]).
                to_return(status: 200,
                          body: JSON.generate(id: 're_123', object: 'refund', status: 'succeeded') )
            end

            it "can still void the payment" do
              order.reload
              expect(order.payment_total).to_not eq 0
              expect(order.outstanding_balance.to_f).to eq 0
              spree_put :fire, params
              expect(payment.reload.state).to eq 'void'
              order.reload
              expect(order.payment_total).to eq 0
              expect(order.outstanding_balance.to_f).to_not eq 0
            end
          end
        end

        context "when the payment has not been confirmed yet" do
          before do
            stub_payment_intent_get_request(response: { intent_status: "requires_action" })
            stub_request(:post, "https://api.stripe.com/v1/payment_intents/pi_123/cancel").
              with(basic_auth: ["sk_test_12345", ""]).
              to_return(status: 200,
                        body: JSON.generate(id: 'pi_123', object: 'payment_intent',
                                            status: 'canceled') )
          end

          it "voids the payment" do
            order.reload
            expect(order.payment_total).to_not eq 0
            expect(order.outstanding_balance.to_f).to eq 0
            spree_put :fire, params
            expect(payment.reload.state).to eq 'void'
            order.reload
            expect(order.payment_total).to eq 0
            expect(order.outstanding_balance.to_f).to_not eq 0
          end
        end
      end
    end

    context "requesting a partial credit on a payment" do
      let(:params) { { id: payment.id, order_id: order.number, e: :credit } }

      # Required for the respond override in the controller decorator to work
      before { @request.env['HTTP_REFERER'] = spree.admin_order_payments_url(payment) }

      context "that was processed by stripe" do
        let!(:payment_method) { create(:stripe_sca_payment_method, distributors: [shop]) }
        let!(:payment) do
          create(:payment, :completed, order: order, payment_method: payment_method,
                                       response_code: 'pi_123', amount: order.total + 5)
        end

        before do
          Stripe.api_key = "sk_test_12345"

          stub_payment_intent_get_request stripe_account_header: false
        end

        context "where the request succeeds" do
          before do
            stub_request(:post, "https://api.stripe.com/v1/charges/ch_1234/refunds").
              with(basic_auth: ["sk_test_12345", ""]).
              to_return(status: 200,
                        body: JSON.generate(id: 're_123', object: 'refund', status: 'succeeded') )
          end

          it "partially refunds the payment" do
            order.reload
            expect(order.payment_total).to eq order.total + 5
            expect(order.outstanding_balance.to_f).to eq(-5)
            spree_put :fire, params
            expect(payment.reload.state).to eq 'completed'
            order.reload
            expect(order.payment_total).to eq order.total
            expect(order.outstanding_balance.to_f).to eq 0
          end
        end

        context "where the request fails" do
          before do
            stub_request(:post, "https://api.stripe.com/v1/charges/ch_1234/refunds").
              with(basic_auth: ["sk_test_12345", ""]).
              to_return(status: 200, body: JSON.generate(error: { message: "Bup-bow!" }) )
          end

          it "does not void the payment" do
            order.reload
            expect(order.payment_total).to eq order.total + 5
            expect(order.outstanding_balance.to_f).to eq(-5)
            spree_put :fire, params
            expect(payment.reload.state).to eq 'completed'
            order.reload
            expect(order.payment_total).to eq order.total + 5
            expect(order.outstanding_balance.to_f).to eq(-5)
            expect(flash[:error]).to eq "Bup-bow!"
          end
        end
      end
    end
  end
end
