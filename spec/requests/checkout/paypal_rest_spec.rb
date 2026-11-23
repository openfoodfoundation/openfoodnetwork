# frozen_string_literal: true

RSpec.describe "checking out with a PayPal REST payment method" do
  include ShopWorkflow
  include PaypalRestHelper

  let!(:address) { create(:address) }
  let!(:shop) { create(:enterprise) }
  let!(:shipping_method) { create(:shipping_method_with, :distributor, distributor: shop) }
  let!(:shipment) { create(:shipment_with, :shipping_method, shipping_method:) }
  let!(:order) do
    create(
      :order, distributor: shop, shipments: [shipment],
              ship_address: address.dup, bill_address: address.dup
    )
  end
  let!(:line_item) { create(:line_item, order:, quantity: 3, price: 5.00) }
  let(:payment_method) { create(:paypal_rest_payment_method) }
  let(:payment) { order.payments.first }
  let(:client) { stub_paypal_rest_client(amount: order.total) }
  let(:params) { { payment_method_id: payment_method.id } }

  before do
    order.reload.update_totals
    order.next # => address
    order.next # => delivery
    order.next # => payment
    pick_order order

    order.payments.create!(payment_method_id: payment_method.id, amount: order.total)
    order.next # => confirmation
    client
  end

  describe "GET /payment_gateways/paypal/rest/create" do
    it "redirects the customer to the PayPal approval URL" do
      get payment_gateways_paypal_rest_path, params: params

      expect(response).to redirect_to('https://paypal.example/approve')
    end

    it "creates a PayPal order with a request ID and return URLs", :aggregate_failures do
      get payment_gateways_paypal_rest_path, params: params

      expect(client).to have_received(:create_order) do |order_request, request_id:|
        context = order_request.payment_source[:paypal][:experience_context]
        expect(request_id).to eq("ofn-create-#{order.number}-#{payment.id}")
        expect(context[:return_url]).to eq(
          payment_gateways_confirm_paypal_rest_url(payment_method_id: payment_method.id)
        )
        expect(context[:cancel_url]).to eq(payment_gateways_cancel_paypal_rest_url)
      end
    end

    it "redirects to the details step when stock is insufficient" do
      check_stock = instance_double(Orders::CheckStockService)
      allow(Orders::CheckStockService).to receive(:new).and_return(check_stock)
      allow(check_stock).to receive(:sufficient_stock?).and_return(false)
      allow(check_stock).to receive(:update_line_items).and_return(order.variants)

      get payment_gateways_paypal_rest_path, params: params

      expect(response).to redirect_to(checkout_step_path(step: :details))
    end

    it "fails without alerting for a benign missing payment", :aggregate_failures do
      payment.update!(state: "failed")
      expect(Alert).not_to receive(:raise_with_record)

      get payment_gateways_paypal_rest_path, params: params

      expect(response).to redirect_to(checkout_step_path(step: :payment))
      expect(flash[:error]).to include('No pending PayPal payment found')
    end

    it "alerts when PayPal fails to create the order", :aggregate_failures do
      allow(client).to receive(:create_order).and_return(
        PaypalRest::Result.new(success: false, error_message: 'PayPal is unavailable')
      )
      expect(Alert).to receive(:raise_with_record)

      get payment_gateways_paypal_rest_path, params: params

      expect(response).to redirect_to(checkout_step_path(step: :payment))
      expect(flash[:error]).to include('PayPal is unavailable')
    end
  end

  describe "GET /payment_gateways/paypal/rest/confirm" do
    let(:confirm_params) { params.merge(token: 'ORDER-1', PayerID: 'PAYER-1') }

    it "stores the PayPal order ID and payer ID on the payment source" do
      get payment_gateways_confirm_paypal_rest_path, params: confirm_params

      expect(payment.reload.source).to have_attributes(
        order_id: 'ORDER-1', payer_id: 'PAYER-1'
      )
    end

    it "fails when there is no pending PayPal payment", :aggregate_failures do
      payment.update!(state: 'failed')

      get payment_gateways_confirm_paypal_rest_path, params: confirm_params

      expect(response).to redirect_to(checkout_step_path(:payment))
      expect(flash[:error]).to eq(Spree.t('flash.no_payment_found', scope: 'paypal'))
    end

    it "stores only the order ID when PayPal returns no payer ID" do
      allow(client).to receive(:capture_order).and_return(
        PaypalRest::Result.new(
          success: true, order_id: 'ORDER-1', capture_id: 'CAPTURE-1', status: 'COMPLETED'
        )
      )

      get payment_gateways_confirm_paypal_rest_path, params: params.merge(token: 'ORDER-1')

      expect(payment.reload.source).to have_attributes(order_id: 'ORDER-1', payer_id: nil)
    end

    it "reuses a source created by a concurrent confirm request", :aggregate_failures do
      existing = Spree::PaypalRestCheckout.create!(order_id: 'ORDER-1')
      new_source = Spree::PaypalRestCheckout.new(order_id: 'ORDER-1')
      allow(Spree::PaypalRestCheckout).to receive(:find_or_initialize_by).and_return(new_source)
      allow(new_source).to receive(:save!).and_raise(ActiveRecord::RecordNotUnique)
      allow(Spree::PaypalRestCheckout).to receive(:find_by!).with(order_id: 'ORDER-1').
        and_return(existing)

      get payment_gateways_confirm_paypal_rest_path, params: confirm_params

      expect(payment.reload.source).to eq(existing)
      expect(existing.reload.payer_id).to eq('PAYER-1')
      expect(order.reload).to be_complete
    end

    it "captures the payment and completes the order", :aggregate_failures do
      get payment_gateways_confirm_paypal_rest_path, params: confirm_params

      expect(response).to redirect_to(order_path(order, order_token: order.token))
      expect(order.reload).to be_complete
      expect(payment.reload).to be_completed
      expect(payment.response_code).to eq('CAPTURE-1')
      expect(payment.source).to have_attributes(
        capture_id: 'CAPTURE-1', payer_id: 'PAYER-1', status: 'COMPLETED'
      )
    end

    it "fails when the token is missing", :aggregate_failures do
      get payment_gateways_confirm_paypal_rest_path, params: params

      expect(response).to redirect_to(checkout_step_path(:payment))
      expect(flash[:error]).to eq(Spree.t('flash.no_payment_found', scope: 'paypal'))
    end

    it "returns to payment step when PayPal rejects the capture", :aggregate_failures do
      allow(client).to receive(:capture_order).and_return(
        PaypalRest::Result.new(success: false, error_message: 'Order expired')
      )

      get payment_gateways_confirm_paypal_rest_path, params: confirm_params

      expect(response).to redirect_to(checkout_step_path(step: :payment))
      expect(payment.reload).not_to be_completed
    end
  end

  describe "GET /payment_gateways/paypal/rest/cancel" do
    it "returns to checkout with a notice", :aggregate_failures do
      get payment_gateways_cancel_paypal_rest_path

      expect(response).to redirect_to(checkout_path)
      expect(flash[:notice]).to eq(Spree.t('flash.cancel', scope: 'paypal'))
    end
  end
end
