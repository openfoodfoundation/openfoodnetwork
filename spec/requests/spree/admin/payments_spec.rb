# frozen_string_literal: true

require "spec_helper"

describe Spree::Admin::PaymentsController, type: :request do
  let(:user) { order.user }
  let(:order) { create(:completed_order_with_fees) }

  before do
    sign_in create(:admin_user)
  end

  describe "PUT /admin/orders/:order_number/payments/:id/fire" do
    let(:payment) do
      create(
        :payment,
        payment_method: stripe_payment_method,
        order:,
        response_code: "pi_123",
        amount: order.total,
        state: "completed"
      )
    end
    let(:stripe_payment_method) do
      create(:stripe_sca_payment_method, distributors: [order.distributor])
    end
    let(:headers) { { HTTP_REFERER: spree.admin_order_payments_url(order) } }

    before do
      order.update(payments: [])
      order.payments << payment
    end

    context "with no event parameter" do
      it "redirect to payments page" do
        put(
          "/admin/orders/#{order.number}/payments/#{order.payments.first.id}/fire",
          params: {},
          headers:
        )

        expect(response).to redirect_to(spree.admin_order_payments_url(order))
      end
    end

    context "with no payment source" do
      it "redirect to payments page" do
        allow(payment).to receive(:payment_source).and_return(nil)

        put(
          "/admin/orders/#{order.number}/payments/#{order.payments.first.id}/fire?e=void",
          params: {},
          headers:
        )

        expect(response).to redirect_to(spree.admin_order_payments_url(order))
      end
    end

    context "with 'void' parameter" do
      before do
        allow(Spree::Payment).to receive(:find).and_return(payment)
      end

      it "calls void_transaction! on payment" do
        expect(payment).to receive(:void_transaction!)

        put(
          "/admin/orders/#{order.number}/payments/#{order.payments.first.id}/fire?e=void",
          params: {},
          headers:
        )
      end

      it "redirect to payments page" do
        allow(payment).to receive(:void_transaction!).and_return(true)

        put(
          "/admin/orders/#{order.number}/payments/#{order.payments.first.id}/fire?e=void",
          params: {},
          headers:
        )

        expect(response).to redirect_to(spree.admin_order_payments_url(order))
        expect(flash[:success]).to eq "Payment Updated"
      end

      context "when void_transaction! fails" do
        it "set an error flash message" do
          allow(payment).to receive(:void_transaction!).and_return(false)

          put(
            "/admin/orders/#{order.number}/payments/#{order.payments.first.id}/fire?e=void",
            params: {},
            headers:
          )

          expect(response).to redirect_to(spree.admin_order_payments_url(order))
          expect(flash[:error]).to eq "Could not update the payment"
        end
      end
    end

    context "when something unexpected happen" do
      before do
        allow(Spree::Payment).to receive(:find).and_return(payment)
        allow(payment).to receive(:void_transaction!).and_raise(StandardError, "Unexpected !")
      end

      it "log the error message" do
        # The redirect_do also calls Rails.logger.error
        expect(Rails.logger).to receive(:error).with("Unexpected !").ordered
        expect(Rails.logger).to receive(:error).with(/Redirected/).ordered

        put(
          "/admin/orders/#{order.number}/payments/#{order.payments.first.id}/fire?e=void",
          params: {},
          headers: { HTTP_REFERER: spree.admin_order_payments_url(order) }
        )

        expect(flash[:error]).to eq "Unexpected !"
      end

      it "redirect to payments page" do
        put(
          "/admin/orders/#{order.number}/payments/#{order.payments.first.id}/fire?e=void",
          params: {},
          headers:
        )

        expect(response).to redirect_to(spree.admin_order_payments_url(order))
      end
    end
  end
end
