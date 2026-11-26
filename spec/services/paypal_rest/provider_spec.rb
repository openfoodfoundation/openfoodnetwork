# frozen_string_literal: true

RSpec.describe PaypalRest::Provider do
  subject(:provider) {
    described_class.new(client_id: 'id', client_secret: 'secret', server: 'sandbox')
  }

  let(:client) { instance_double(PaypalRest::Client) }

  before { allow(PaypalRest::Client).to receive(:new).and_return(client) }

  describe "#create_order" do
    it "delegates to the client" do
      expect(client).to receive(:create_order).with(:order_request, request_id: 'req-1')

      provider.create_order(:order_request, request_id: 'req-1')
    end
  end

  describe "#purchase" do
    let(:source) { Spree::PaypalRestCheckout.create!(order_id: 'ORDER-123') }
    let(:paypal_order) do
      PaypalRest::Result.new(success: true, amount: '10.00', currency_code: 'AUD')
    end

    before do
      allow(client).to receive(:order_amount).with('ORDER-123').and_return(paypal_order)
    end

    it "captures the order and stores the capture details" do
      result = PaypalRest::Result.new(
        success: true,
        capture_id: 'CAPTURE-1',
        payer_id: 'PAYER-1',
        status: 'COMPLETED'
      )
      expect(client).to receive(:capture_order)
        .with('ORDER-123', {}, request_id: 'ofn-capture-ORDER-123')
        .and_return(result)

      response = provider.purchase(1000, source)

      expect(response).to be_success
      expect(response.authorization).to eq('CAPTURE-1')
      expect(source.reload).to have_attributes(
        capture_id: 'CAPTURE-1', payer_id: 'PAYER-1', status: 'COMPLETED'
      )
    end

    it "fails when the PayPal order amount differs from the payment amount" do
      allow(paypal_order).to receive(:amount).and_return('12.00')

      expect(client).not_to receive(:capture_order)

      response = provider.purchase(1000, source)

      expect(response).not_to be_success
      expect(response.message).to include('does not match payment amount')
    end

    it "fails when the order lookup fails" do
      allow(client).to receive(:order_amount).and_return(
        PaypalRest::Result.new(success: false, error_message: 'Order not found')
      )

      expect(client).not_to receive(:capture_order)

      response = provider.purchase(1000, source)

      expect(response.message).to eq('Order not found')
    end

    it "fails when the source has no PayPal order ID" do
      source.order_id = nil

      expect(client).not_to receive(:order_amount)
      expect(client).not_to receive(:capture_order)

      response = provider.purchase(1000, source)

      expect(response).not_to be_success
      expect(response.message).to eq('Missing PayPal order ID')
    end

    it "returns the PayPal error when the capture fails" do
      result = PaypalRest::Result.new(success: false, error_message: 'Order expired')
      allow(client).to receive(:capture_order).and_return(result)

      response = provider.purchase(1000, source)

      expect(response).not_to be_success
      expect(response.message).to eq('Order expired')
    end
  end

  describe "unsupported operations" do
    %i[authorize capture credit void].each do |operation|
      it "returns a clean failure for ##{operation}" do
        response = provider.public_send(operation, 1000, 'CAPTURE-1', {})

        expect(response).not_to be_success
        expect(response.message).to eq(
          "#{operation} is not supported for immediate-capture PayPal payments"
        )
      end
    end
  end

  describe "#refund" do
    let(:source) do
      Spree::PaypalRestCheckout.create!(
        order_id: 'ORDER-123', capture_id: 'CAPTURE-1', status: 'COMPLETED'
      )
    end
    let(:payment) do
      create(:payment, :completed, source:, amount: 10, response_code: 'CAPTURE-1')
    end
    let(:options) { { currency: 'AUD', payment: payment } }

    it "returns an ActiveMerchant response and stores the refund details" do
      result = PaypalRest::Result.new(success: true, refund_id: 'REFUND-1', status: 'COMPLETED')

      expect(client).to receive(:refund_capture) do |capture_id, request, request_id:|
        expect(capture_id).to eq('CAPTURE-1')
        expect(request).to be_a(PaypalServerSdk::RefundRequest)
        expect(request.amount).to have_attributes(value: '10.00', currency_code: 'AUD')
        expect(request_id).to eq('ofn-refund-CAPTURE-1-10.00')
        result
      end

      response = provider.refund(1000, 'CAPTURE-1', options)

      expect(response).to be_success
      expect(response.authorization).to eq('REFUND-1')
      expect(source.reload).to have_attributes(refund_id: 'REFUND-1', status: 'refunded')
      expect(source.refunded_at).to be_present
    end

    it "fails when there is no capture ID" do
      expect(client).not_to receive(:refund_capture)

      response = provider.refund(1000, nil, options)

      expect(response).not_to be_success
      expect(response.message).to eq('Missing PayPal capture ID')
    end

    it "returns the PayPal error without changing the source" do
      failure = PaypalRest::Result.new(success: false, error_message: 'Capture already refunded')
      allow(client).to receive(:refund_capture).and_return(failure)

      response = provider.refund(1000, 'CAPTURE-1', options)

      expect(response).not_to be_success
      expect(response.message).to eq('Capture already refunded')
      expect(source.reload).to have_attributes(refund_id: nil, status: 'COMPLETED')
    end

    it "fails loudly when the options have no payment" do
      expect(client).not_to receive(:refund_capture)

      response = provider.refund(1000, 'CAPTURE-1', { currency: 'AUD' })

      expect(response).not_to be_success
      expect(response.message).to eq('Missing payment for PayPal refund')
    end

    it "fails loudly when the payment has no source" do
      payment_without_source = build(:payment, source: nil)

      expect(client).not_to receive(:refund_capture)

      response = provider.refund(
        1000, 'CAPTURE-1', { currency: 'AUD', payment: payment_without_source }
      )

      expect(response).not_to be_success
      expect(response.message).to eq('Missing payment source for PayPal refund')
    end
  end
end
