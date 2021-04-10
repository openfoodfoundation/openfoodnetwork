# frozen_string_literal: true

require 'spec_helper'

describe Checkout::StripeRedirect do
  describe '#path' do
    let(:order) { create(:order) }
    let(:params) { { order: { order_id: order.id } } }

    let(:redirect) { Checkout::StripeRedirect.new(params, order) }

    it "returns nil if payment_attributes are not provided" do
      expect(redirect.path).to be nil
    end

    describe "when payment_attributes are provided" do
      it "raises an error if payment method does not exist" do
        params[:order][:payments_attributes] = [{ payment_method_id: "123" }]

        expect { redirect.path }.to raise_error ActiveRecord::RecordNotFound
      end

      describe "when payment method provided exists" do
        before { params[:order][:payments_attributes] = [{ payment_method_id: payment_method.id }] }

        describe "and the payment method is not a stripe payment method" do
          let(:payment_method) { create(:payment_method) }

          it "returns nil" do
            expect(redirect.path).to be nil
          end
        end

        describe "and the payment method is a stripe method" do
          let(:distributor) { create(:distributor_enterprise) }
          let(:payment_method) { create(:stripe_sca_payment_method) }

          it "returns the redirect path" do
            stripe_payment = create(:payment, payment_method_id: payment_method.id)
            order.payments << stripe_payment
            allow(OrderPaymentFinder).to receive_message_chain(:new, :last_pending_payment).
              and_return(stripe_payment)
            allow(stripe_payment).to receive(:authorize!) do
              # Authorization moves the payment state from checkout/processing to pending
              stripe_payment.state = 'pending'
              true
            end
            allow(stripe_payment.order).to receive(:distributor) { distributor }
            test_redirect_url = "http://stripe_auth_url/"
            allow(stripe_payment).to receive(:cvv_response_message).and_return(test_redirect_url)

            expect(redirect.path).to eq test_redirect_url
          end
        end
      end
    end
  end
end
