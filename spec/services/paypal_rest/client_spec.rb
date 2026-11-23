# frozen_string_literal: true

RSpec.describe PaypalRest::Client do
  subject(:client) {
    described_class.new(client_id: 'id', client_secret: 'secret', environment: 'sandbox')
  }

  let(:sdk) { instance_double(PaypalServerSdk::Client) }
  let(:orders) { instance_double(PaypalServerSdk::OrdersController) }
  let(:payments) { instance_double(PaypalServerSdk::PaymentsController) }
  let(:sdk_response) {
    Struct.new(:status_code, :raw_body, :reason_phrase).new(
      400, '{"errors":[{"description":"bad request"}]}', 'Bad Request'
    )
  }
  let(:sdk_exception) { PaypalServerSdk::APIException.new('bad request', sdk_response) }

  before do
    allow(PaypalServerSdk::Client).to receive(:new).and_return(sdk)
    allow(sdk).to receive(:orders).and_return(orders)
    allow(sdk).to receive(:payments).and_return(payments)
  end

  describe "#initialize" do
    it "selects the production environment for live servers" do
      expect(PaypalServerSdk::Client).to receive(:new).with(
        client_credentials_auth_credentials: an_instance_of(
          PaypalServerSdk::ClientCredentialsAuthCredentials
        ),
        environment: PaypalServerSdk::Environment::PRODUCTION
      ).and_return(sdk)

      described_class.new(client_id: 'id', client_secret: 'secret', environment: 'live')
    end
  end

  describe "#create_order" do
    let(:approval_link) {
      instance_double(PaypalServerSdk::LinkDescription, rel: 'approve',
                                                        href: 'https://paypal.example/approve')
    }
    let(:order) {
      instance_double(PaypalServerSdk::Order, id: 'ORDER-1', status: 'CREATED',
                                              links: [approval_link])
    }
    let(:response) {
      instance_double(PaypalServerSdk::ApiResponse, success?: true, data: order, errors: nil)
    }

    it "returns the order ID and approval URL" do
      expect(orders).to receive(:create_order)
        .with({ 'body' => :order_request, 'paypal_request_id' => 'req-1' })
        .and_return(response)

      result = client.create_order(:order_request, request_id: 'req-1')

      expect(result).to be_success
      expect(result).to have_attributes(
        order_id: 'ORDER-1', approval_url: 'https://paypal.example/approve', status: 'CREATED'
      )
    end

    it "fails when PayPal returns no order ID" do
      allow(order).to receive(:id).and_return(nil)
      allow(orders).to receive(:create_order).and_return(response)

      expect(client.create_order(:order_request)).to be_failure
    end

    it "returns no approval URL when PayPal provides no approval link" do
      allow(order).to receive(:links).and_return([])
      allow(orders).to receive(:create_order).and_return(response)

      result = client.create_order(:order_request)

      expect(result).to be_success
      expect(result.approval_url).to be_nil
    end

    it "converts SDK exceptions into failures" do
      allow(orders).to receive(:create_order).and_raise(SocketError, 'connection refused')

      result = client.create_order(:order_request)

      expect(result).to be_failure
      expect(result.error_message).to eq('connection refused')
    end
  end

  describe "#order_amount" do
    let(:amount) { PaypalServerSdk::Money.new(value: '10.00', currency_code: 'AUD') }
    let(:purchase_unit) { instance_double(PaypalServerSdk::PurchaseUnit, amount:) }
    let(:order) { instance_double(PaypalServerSdk::Order, purchase_units: [purchase_unit]) }
    let(:response) {
      instance_double(PaypalServerSdk::ApiResponse, success?: true, data: order, errors: nil)
    }

    it "returns the approved amount and currency" do
      expect(orders).to receive(:get_order)
        .with({ 'id' => 'ORDER-1', 'paypal_request_id' => 'req-amount' })
        .and_return(response)

      result = client.order_amount('ORDER-1', request_id: 'req-amount')

      expect(result).to be_success
      expect(result).to have_attributes(amount: '10.00', currency_code: 'AUD')
    end

    it "fails when PayPal returns no amount" do
      allow(order).to receive(:purchase_units).and_return([])
      allow(orders).to receive(:get_order).and_return(response)

      result = client.order_amount('ORDER-1')

      expect(result).to be_failure
      expect(result.error_message).to eq('PayPal did not return an order amount')
    end

    it "converts SDK exceptions into failures" do
      allow(orders).to receive(:get_order).and_raise(sdk_exception)

      expect(client.order_amount('ORDER-1').error_message).to eq('bad request')
    end
  end

  describe "#capture_order" do
    let(:capture) { instance_double(PaypalServerSdk::CapturedPayment, id: 'CAPTURE-1', status: 'COMPLETED') }
    let(:capture_payments) {
      instance_double(PaypalServerSdk::PaymentCollection, captures: [capture])
    }
    let(:payer) { instance_double(PaypalServerSdk::Payer, payer_id: 'PAYER-1') }
    let(:purchase_unit) { instance_double(PaypalServerSdk::PurchaseUnit, payments: capture_payments) }
    let(:order) {
      instance_double(PaypalServerSdk::Order, id: 'ORDER-1', payer: payer,
                                              purchase_units: [purchase_unit])
    }
    let(:response) {
      instance_double(PaypalServerSdk::ApiResponse, success?: true, data: order, errors: nil)
    }

    it "returns the capture and payer details" do
      expect(orders).to receive(:capture_order)
        .with({ 'id' => 'ORDER-1', 'body' => {}, 'paypal_request_id' => 'req-2' })
        .and_return(response)

      result = client.capture_order('ORDER-1', {}, request_id: 'req-2')

      expect(result).to be_success
      expect(result).to have_attributes(
        order_id: 'ORDER-1', capture_id: 'CAPTURE-1', payer_id: 'PAYER-1', status: 'COMPLETED'
      )
    end

    it "fails when the capture is not completed" do
      allow(capture).to receive(:status).and_return('PENDING')
      allow(orders).to receive(:capture_order).and_return(response)

      result = client.capture_order('ORDER-1')

      expect(result).to be_failure
      expect(result.error_message).to eq('PayPal capture status: PENDING')
    end

    it "fails when PayPal returns no capture ID" do
      allow(capture).to receive(:id).and_return(nil)
      allow(orders).to receive(:capture_order).and_return(response)

      expect(client.capture_order('ORDER-1')).to be_failure
    end

    it "converts SDK exceptions into failures" do
      allow(orders).to receive(:capture_order).and_raise(sdk_exception)

      expect(client.capture_order('ORDER-1').error_message).to eq('bad request')
    end
  end

  describe "#refund_capture" do
    let(:refund) { instance_double(PaypalServerSdk::Refund, id: 'REFUND-1', status: 'COMPLETED') }
    let(:response) {
      instance_double(PaypalServerSdk::ApiResponse, success?: true, data: refund, errors: nil)
    }

    it "returns the refund ID" do
      expect(payments).to receive(:refund_captured_payment)
        .with({ 'capture_id' => 'CAPTURE-1', 'body' => { amount: {} },
                'paypal_request_id' => 'req-3' })
        .and_return(response)

      result = client.refund_capture('CAPTURE-1', { amount: {} }, request_id: 'req-3')

      expect(result).to be_success
      expect(result).to have_attributes(refund_id: 'REFUND-1', status: 'COMPLETED')
    end

    it "fails when the refund is not completed" do
      allow(refund).to receive(:status).and_return('PENDING')
      allow(payments).to receive(:refund_captured_payment).and_return(response)

      result = client.refund_capture('CAPTURE-1', {})

      expect(result).to be_failure
      expect(result.error_message).to eq('PayPal refund status: PENDING')
    end

    it "converts SDK exceptions into failures" do
      allow(payments).to receive(:refund_captured_payment).and_raise(sdk_exception)

      expect(client.refund_capture('CAPTURE-1', {}).error_message).to eq('bad request')
    end
  end

  describe "error responses" do
    it "uses the SDK error messages" do
      error = instance_double(PaypalServerSdk::ErrorDetails, to_s: 'Invalid request',
                                                             description: nil)
      response = instance_double(PaypalServerSdk::ApiResponse, success?: false,
                                                               errors: [error], data: nil)
      allow(orders).to receive(:create_order).and_return(response)

      result = client.create_order(:order_request)

      expect(result).to be_failure
      expect(result.error_message).to eq('Invalid request')
    end

    it "prefers the human-readable SDK error description" do
      error = instance_double(PaypalServerSdk::ErrorDetails,
                              description: 'Order amount does not match', to_s: '#<Error ...>')
      response = instance_double(PaypalServerSdk::ApiResponse, success?: false,
                                                               errors: [error], data: nil)
      allow(orders).to receive(:create_order).and_return(response)

      result = client.create_order(:order_request)

      expect(result.error_message).to eq('Order amount does not match')
    end
  end
end
