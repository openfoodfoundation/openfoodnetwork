# frozen_string_literal: true

RSpec.describe Spree::Admin::PaymentsController do
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

    context "when a gateway error happens" do
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

    context "with a VINE voucher", feature: :connected_apps do
      let(:vine_voucher) {
        create(:vine_voucher, code: 'some_code', enterprise: order.distributor, amount: 6)
      }
      let(:vine_voucher_redeemer) { instance_double(Vine::VoucherRedeemerService) }

      before do
        add_voucher_to_order(vine_voucher, order)

        allow(Vine::VoucherRedeemerService).to receive(:new).and_return(vine_voucher_redeemer)
      end

      it "completes the order and redirects to payment page" do
        expect(vine_voucher_redeemer).to receive(:redeem).and_return(true)

        post("/admin/orders/#{order.number}/payments.json", params:)

        expect(response).to redirect_to(spree.admin_order_payments_path(order))
        expect(flash[:success]).to eq "Payment has been successfully created!"

        expect(order.reload.state).to eq "complete"
      end

      context "when redeeming the voucher fails" do
        it "redirect to payments page" do
          allow(vine_voucher_redeemer).to receive(:redeem).and_return(false)
          allow(vine_voucher_redeemer).to receive(:errors).and_return(
            { redeeming_failed: "Redeeming the voucher failed" }
          )

          post("/admin/orders/#{order.number}/payments.json", params:)

          expect(response).to redirect_to(spree.admin_order_payments_path(order))
          expect(flash[:error]).to match "Redeeming the voucher failed"
        end
      end

      context "when an other error happens" do
        it "redirect to payments page" do
          allow(vine_voucher_redeemer).to receive(:redeem).and_return(false)
          allow(vine_voucher_redeemer).to receive(:errors).and_return(
            { vine_api: "There was an error communicating with the API" }
          )

          post("/admin/orders/#{order.number}/payments.json", params:)

          expect(response).to redirect_to(spree.admin_order_payments_path(order))
          expect(flash[:error]).to match "There was an error while trying to redeem your voucher"
        end
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
        put(
          "/admin/orders/#{order.number}/payments/#{order.payments.first.id}/fire?e=void",
          params: {},
          headers:
        )

        expect(response).to redirect_to(spree.admin_order_payments_url(order))
      end
    end

    context "with 'void' event" do
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

    context "with 'capture_and_complete_order' event" do
      before do
        allow(Spree::Payment).to receive(:find).and_return(payment)
      end

      it "calls capture_and_complete_order! on payment" do
        expect(payment).to receive(:capture_and_complete_order!)

        put(
          "/admin/orders/#{order.number}/payments/#{order.payments.first.id}/" \
          "fire?e=capture_and_complete_order",
          params: {},
          headers:
        )
      end

      it "redirect to payments page" do
        allow(payment).to receive(:capture_and_complete_order!).and_return(true)

        put(
          "/admin/orders/#{order.number}/payments/#{order.payments.first.id}/" \
          "fire?e=capture_and_complete_order",
          params: {},
          headers:
        )

        expect(response).to redirect_to(spree.admin_order_payments_url(order))
        expect(flash[:success]).to eq "Payment Updated"
      end

      context "when capture_and_complete_order! fails" do
        it "set an error flash message" do
          allow(payment).to receive(:capture_and_complete_order!).and_return(false)

          put(
            "/admin/orders/#{order.number}/payments/#{order.payments.first.id}/" \
            "fire?e=capture_and_complete_order",
            params: {},
            headers:
          )

          expect(response).to redirect_to(spree.admin_order_payments_url(order))
          expect(flash[:error]).to eq "Could not update the payment"
        end
      end

      context "with a VINE voucher", feature: :connected_apps do
        let(:vine_voucher) {
          create(:vine_voucher, code: 'some_code', enterprise: order.distributor, amount: 6)
        }
        let(:vine_voucher_redeemer) { instance_double(Vine::VoucherRedeemerService) }

        before do
          add_voucher_to_order(vine_voucher, order)

          allow(Vine::VoucherRedeemerService).to receive(:new).and_return(vine_voucher_redeemer)
        end

        it "completes the order and redirects to payment page" do
          expect(vine_voucher_redeemer).to receive(:redeem).and_return(true)

          put(
            "/admin/orders/#{order.number}/payments/#{order.payments.first.id}/" \
            "fire?e=capture_and_complete_order",
            params: {},
            headers:
          )

          expect(response).to redirect_to(spree.admin_order_payments_url(order))
          expect(flash[:success]).to eq "Payment Updated"

          expect(order.reload.state).to eq "complete"
        end

        context "when redeeming the voucher fails" do
          it "redirect to payments page" do
            allow(vine_voucher_redeemer).to receive(:redeem).and_return(false)
            allow(vine_voucher_redeemer).to receive(:errors).and_return(
              { redeeming_failed: "Redeeming the voucher failed" }
            )

            put(
              "/admin/orders/#{order.number}/payments/#{order.payments.first.id}/" \
              "fire?e=capture_and_complete_order",
              params: {},
              headers:
            )

            expect(response).to redirect_to(spree.admin_order_payments_url(order))
            expect(flash[:error]).to match "Redeeming the voucher failed"
          end
        end

        context "when an other error happens" do
          it "redirect to payments page" do
            allow(vine_voucher_redeemer).to receive(:redeem).and_return(false)
            allow(vine_voucher_redeemer).to receive(:errors).and_return(
              { vine_api: "There was an error communicating with the API" }
            )

            put(
              "/admin/orders/#{order.number}/payments/#{order.payments.first.id}/" \
              "fire?e=capture_and_complete_order",
              params: {},
              headers:
            )

            expect(response).to redirect_to(spree.admin_order_payments_url(order))
            expect(flash[:error]).to match "There was an error while trying to redeem your voucher"
          end
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

  def add_voucher_to_order(voucher, order)
    voucher.create_adjustment(voucher.code, order)
    OrderManagement::Order::Updater.new(order).update_voucher
  end
end
