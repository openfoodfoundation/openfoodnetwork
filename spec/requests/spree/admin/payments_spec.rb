# frozen_string_literal: true

require "spec_helper"

RSpec.describe Spree::Admin::PaymentsController, type: :request do
  let(:user) { order.user }
  let(:order) { create(:completed_order_with_fees) }

  before do
    sign_in create(:admin_user)
  end

  describe "POST /admin/orders/:order_number/payments.json" do
    let(:params) do
      {
        payment: {
          payment_method_id: payment_method.id, amount: order.total
        }
      }
    end
    let(:payment_method) do
      create(:payment_method, distributors: [order.distributor])
    end

    it "creates a payment" do
      expect {
        post("/admin/orders/#{order.number}/payments.json", params:)
      }.to change { order.payments.count }.by(1)
    end

    it "redirect to payments page" do
      post("/admin/orders/#{order.number}/payments.json", params:)

      expect(response).to redirect_to(spree.admin_order_payments_path(order))
      expect(flash[:success]).to eq "Payment has been successfully created!"
    end

    context "when failing to create payment" do
      it "redirects to payments page" do
        payment_mock = instance_double(Spree::Payment)
        allow(order.payments).to receive(:build).and_return(payment_mock)
        allow(payment_mock).to receive(:save).and_return(false)

        post("/admin/orders/#{order.number}/payments.json", params:)

        expect(response).to redirect_to(spree.admin_order_payments_path(order))
      end
    end

    context "when a getway error happens" do
      let(:payment_method) do
        create(:stripe_sca_payment_method, distributors: [order.distributor])
      end

      it "redirect to payments page" do
        allow(Spree::Order).to receive(:find_by!).and_return(order)

        stripe_sca_payment_authorize =
          instance_double(OrderManagement::Order::StripeScaPaymentAuthorize)
        allow(OrderManagement::Order::StripeScaPaymentAuthorize).to receive(:new)
          .and_return(stripe_sca_payment_authorize)
        # Simulate an error
        allow(stripe_sca_payment_authorize).to receive(:call!) do
          order.errors.add(:base, "authorization_failure")
        end

        post("/admin/orders/#{order.number}/payments.json", params:)

        expect(response).to redirect_to(spree.admin_order_payments_path(order))
        expect(flash[:error]).to eq("Authorization Failure")
      end
    end
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
        expect(Bugsnag).to receive(:notify).with(StandardError)

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
