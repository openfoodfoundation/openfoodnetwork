# frozen_string_literal: true

require 'spec_helper'

describe Checkout::StripeRedirect do
  describe '#path' do
    let(:order) { create(:order) }
    let(:service) { Checkout::StripeRedirect.new(payment_method, order) }

    context "when the given payment method is not Stripe SCA" do
      let(:payment_method) { build(:payment_method) }

      it "returns nil" do
        expect(service.path).to be nil
      end
    end

    context "when the payment method is a Stripe method" do
      let(:payment_method) { create(:stripe_sca_payment_method) }
      let(:stripe_payment) { create(:payment, payment_method_id: payment_method.id) }
      let(:test_redirect_url) { "http://stripe_auth_url/" }

      before do
        order.payments << stripe_payment
      end

      it "authorizes the payment and returns the redirect path" do
        expect(OrderPaymentFinder).to receive_message_chain(:new, :last_pending_payment).
          and_return(stripe_payment)

        expect(OrderManagement::Order::StripeScaPaymentAuthorize).to receive(:new).and_call_original

        expect(stripe_payment).to receive(:authorize!) do
          # Authorization moves the payment state from checkout/processing to pending
          stripe_payment.state = 'pending'
          true
        end

        expect(stripe_payment).to receive(:cvv_response_message).and_return(test_redirect_url)

        expect(service.path).to eq test_redirect_url
      end
    end
  end
end
