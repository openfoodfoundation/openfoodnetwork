# frozen_string_literal: true

require 'spec_helper'
require 'spree/core/gateway_error'

describe Spree::Admin::PaymentsController, type: :controller do
  let!(:shop) { create(:enterprise) }
  let!(:user) { shop.owner }
  let!(:order) { create(:order, distributor: shop, state: 'complete') }
  let!(:line_item) { create(:line_item, order: order, price: 5.0) }

  before do
    allow(controller).to receive(:spree_current_user) { user }
    order.reload.update_totals
  end

  context "Stripe Connect" do
    context "requesting a refund on a payment" do
      let(:params) { { id: payment.id, order_id: order.number, e: :void } }

      # Required for the respond override in the controller decorator to work
      before { @request.env['HTTP_REFERER'] = spree.admin_order_payments_url(payment) }

      context "that was processed by stripe" do
        let!(:payment_method) { create(:stripe_payment_method, distributors: [shop]) }
        let!(:payment) do
          create(:payment, order: order, state: 'completed', payment_method: payment_method,
                           response_code: 'ch_1a2b3c', amount: order.total)
        end

        before do
          allow(Stripe).to receive(:api_key) { "sk_test_12345" }
        end

        context "where the request succeeds" do
          before do
            stub_request(:post, "https://api.stripe.com/v1/charges/ch_1a2b3c/refunds").
              with(basic_auth: ["sk_test_12345", ""]).
              to_return(status: 200,
                        body: JSON.generate(id: 're_123', object: 'refund', status: 'succeeded') )
          end

          it "voids the payment" do
            order.reload
            expect(order.payment_total).to_not eq 0
            expect(order.outstanding_balance).to eq 0
            spree_put :fire, params
            expect(payment.reload.state).to eq 'void'
            order.reload
            expect(order.payment_total).to eq 0
            expect(order.outstanding_balance).to_not eq 0
          end
        end

        context "where the request fails" do
          before do
            stub_request(:post, "https://api.stripe.com/v1/charges/ch_1a2b3c/refunds").
              with(basic_auth: ["sk_test_12345", ""]).
              to_return(status: 200, body: JSON.generate(error: { message: "Bup-bow!" }) )
          end

          it "does not void the payment" do
            order.reload
            expect(order.payment_total).to_not eq 0
            expect(order.outstanding_balance).to eq 0
            spree_put :fire, params
            expect(payment.reload.state).to eq 'completed'
            order.reload
            expect(order.payment_total).to_not eq 0
            expect(order.outstanding_balance).to eq 0
            expect(flash[:error]).to eq "Bup-bow!"
          end
        end
      end
    end

    context "requesting a partial credit on a payment" do
      let(:params) { { id: payment.id, order_id: order.number, e: :credit } }

      # Required for the respond override in the controller decorator to work
      before { @request.env['HTTP_REFERER'] = spree.admin_order_payments_url(payment) }

      context "that was processed by stripe" do
        let!(:payment_method) { create(:stripe_payment_method, distributors: [shop]) }
        let!(:payment) do
          create(:payment, order: order, state: 'completed', payment_method: payment_method,
                           response_code: 'ch_1a2b3c', amount: order.total + 5)
        end

        before do
          allow(Stripe).to receive(:api_key) { "sk_test_12345" }
        end

        context "where the request succeeds" do
          before do
            stub_request(:post, "https://api.stripe.com/v1/charges/ch_1a2b3c/refunds").
              with(basic_auth: ["sk_test_12345", ""]).
              to_return(status: 200,
                        body: JSON.generate(id: 're_123', object: 'refund', status: 'succeeded') )
          end

          it "partially refunds the payment" do
            order.reload
            expect(order.payment_total).to eq order.total + 5
            expect(order.outstanding_balance).to eq(-5)
            spree_put :fire, params
            expect(payment.reload.state).to eq 'completed'
            order.reload
            expect(order.payment_total).to eq order.total
            expect(order.outstanding_balance).to eq 0
          end
        end

        context "where the request fails" do
          before do
            stub_request(:post, "https://api.stripe.com/v1/charges/ch_1a2b3c/refunds").
              with(basic_auth: ["sk_test_12345", ""]).
              to_return(status: 200, body: JSON.generate(error: { message: "Bup-bow!" }) )
          end

          it "does not void the payment" do
            order.reload
            expect(order.payment_total).to eq order.total + 5
            expect(order.outstanding_balance).to eq(-5)
            spree_put :fire, params
            expect(payment.reload.state).to eq 'completed'
            order.reload
            expect(order.payment_total).to eq order.total + 5
            expect(order.outstanding_balance).to eq(-5)
            expect(flash[:error]).to eq "Bup-bow!"
          end
        end
      end
    end
  end

  context "StripeSCA" do
    context "requesting a refund on a payment" do
      let(:params) { { id: payment.id, order_id: order.number, e: :void } }

      # Required for the respond override in the controller decorator to work
      before { @request.env['HTTP_REFERER'] = spree.admin_order_payments_url(payment) }

      context "that was processed by stripe" do
        let!(:payment_method) { create(:stripe_sca_payment_method, distributors: [shop]) }
        let!(:payment) do
          create(:payment, order: order, state: 'completed', payment_method: payment_method,
                           response_code: 'pi_123', amount: order.total)
        end
        let(:stripe_account) { create(:stripe_account, enterprise: shop) }

        before do
          allow(Stripe).to receive(:api_key) { "sk_test_12345" }
          allow(StripeAccount).to receive(:find_by) { stripe_account }

          # Retrieves payment intent info
          stub_request(:get, "https://api.stripe.com/v1/payment_intents/pi_123")
            .with(headers: { 'Stripe-Account' => 'abc123' })
            .to_return({ status: 200, body: JSON.generate(
              amount_received: 2000,
              charges: { data: [{ id: "ch_1a2b3c" }] }
            ) })
        end

        context "where the request succeeds" do
          before do
            # Issues the refund
            stub_request(:post, "https://api.stripe.com/v1/charges/ch_1a2b3c/refunds").
              with(basic_auth: ["sk_test_12345", ""]).
              to_return(status: 200,
                        body: JSON.generate(id: 're_123', object: 'refund', status: 'succeeded') )
          end

          it "voids the payment" do
            order.reload
            expect(order.payment_total).to_not eq 0
            expect(order.outstanding_balance).to eq 0
            spree_put :fire, params
            expect(payment.reload.state).to eq 'void'
            order.reload
            expect(order.payment_total).to eq 0
            expect(order.outstanding_balance).to_not eq 0
          end
        end

        context "where the request fails" do
          before do
            stub_request(:post, "https://api.stripe.com/v1/charges/ch_1a2b3c/refunds").
              with(basic_auth: ["sk_test_12345", ""]).
              to_return(status: 200, body: JSON.generate(error: { message: "Bup-bow!" }) )
          end

          it "does not void the payment" do
            order.reload
            expect(order.payment_total).to_not eq 0
            expect(order.outstanding_balance).to eq 0
            spree_put :fire, params
            expect(payment.reload.state).to eq 'completed'
            order.reload
            expect(order.payment_total).to_not eq 0
            expect(order.outstanding_balance).to eq 0
            expect(flash[:error]).to eq "Bup-bow!"
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
          create(:payment, order: order, state: 'completed', payment_method: payment_method,
                           response_code: 'pi_123', amount: order.total + 5)
        end

        before do
          allow(Stripe).to receive(:api_key) { "sk_test_12345" }

          # Retrieves payment intent info
          stub_request(:get, "https://api.stripe.com/v1/payment_intents/pi_123")
            .to_return({ status: 200, body: JSON.generate(
              amount_received: 2000,
              charges: { data: [{ id: "ch_1a2b3c" }] }
            ) })
        end

        context "where the request succeeds" do
          before do
            stub_request(:post, "https://api.stripe.com/v1/charges/ch_1a2b3c/refunds").
              with(basic_auth: ["sk_test_12345", ""]).
              to_return(status: 200,
                        body: JSON.generate(id: 're_123', object: 'refund', status: 'succeeded') )
          end

          it "partially refunds the payment" do
            order.reload
            expect(order.payment_total).to eq order.total + 5
            expect(order.outstanding_balance).to eq(-5)
            spree_put :fire, params
            expect(payment.reload.state).to eq 'completed'
            order.reload
            expect(order.payment_total).to eq order.total
            expect(order.outstanding_balance).to eq 0
          end
        end

        context "where the request fails" do
          before do
            stub_request(:post, "https://api.stripe.com/v1/charges/ch_1a2b3c/refunds").
              with(basic_auth: ["sk_test_12345", ""]).
              to_return(status: 200, body: JSON.generate(error: { message: "Bup-bow!" }) )
          end

          it "does not void the payment" do
            order.reload
            expect(order.payment_total).to eq order.total + 5
            expect(order.outstanding_balance).to eq(-5)
            spree_put :fire, params
            expect(payment.reload.state).to eq 'completed'
            order.reload
            expect(order.payment_total).to eq order.total + 5
            expect(order.outstanding_balance).to eq(-5)
            expect(flash[:error]).to eq "Bup-bow!"
          end
        end
      end
    end
  end
end
