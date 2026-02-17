# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::PaymentMethod::Taler do
  subject(:taler) {
    Spree::PaymentMethod::Taler.new(
      preferred_backend_url: backend_url,
      preferred_api_key: "sandbox",
    )
  }
  let(:backend_url) { "https://backend.demo.taler.net/instances/sandbox" }

  describe "#external_payment_url", vcr: true do
    it "creates an order reference and retrieves a URL to pay at" do
      order = create(:order_ready_for_confirmation, payment_method: taler)

      url = subject.external_payment_url(order:)
      expect(url).to eq "#{backend_url}/orders/2026.022-0284X4GE8WKMJ"

      payment = order.payments.last.reload
      expect(payment.response_code).to match "2026.022-0284X4GE8WKMJ"
    end
  end

  describe "#purchase" do
    let(:money) { 100 }
    let(:source) { taler }
    let(:payment) { build(:payment, response_code: "taler-order-7") }
    let(:order_url) { "#{backend_url}/private/orders/taler-order-7" }

    it "returns an ActiveMerchant response" do
      order_status = "paid"
      stub_request(:get, order_url).to_return(body: { order_status: }.to_json)

      response = taler.purchase(nil, nil, payment:)

      expect(response.success?).to eq true
      expect(response.message).to eq "paid"
    end

    it "translates error messages" do
      order_status = "claimed"
      stub_request(:get, order_url).to_return(body: { order_status: }.to_json)

      response = taler.purchase(nil, nil, payment:)

      expect(response.success?).to eq false
      expect(response.message).to eq "The payment request expired. Please try again."
    end
  end

  describe "#credit" do
    let(:order_endpoint) { "#{backend_url}/private/orders/taler-order-8" }
    let(:refund_endpoint) { "#{order_endpoint}/refund" }
    let(:taler_refund_uri) {
      "taler://refund/backend.demo.taler.net/instances/sandbox/taler-order-8/"
    }

    it "starts the refund process" do
      order_status = { order_status: "paid" }
      stub_request(:get, order_endpoint).to_return(body: order_status.to_json)
      stub_request(:post, refund_endpoint).to_return(body: { taler_refund_uri: }.to_json)

      order = create(:completed_order_with_totals)
      order.payments.create(
        amount: order.total, state: :completed,
        payment_method: taler,
        response_code: "taler-order-8",
      )
      expect {
        response = taler.credit(100, { payment: order.payments[0] })
        expect(response.success?).to eq true
      }.to enqueue_mail(PaymentMailer, :refund_available)
    end

    it "raises an error if payment hasn't been taken yet" do
      order_status = { order_status: "claimed" }
      stub_request(:get, order_endpoint).to_return(body: order_status.to_json)

      order = create(:completed_order_with_totals)
      order.payments.create(
        amount: order.total, state: :completed,
        payment_method: taler,
        response_code: "taler-order-8",
      )
      expect {
        taler.credit(100, { payment: order.payments[0] })
      }.to raise_error StandardError, "Unsupported action"
    end
  end

  describe "#void" do
    let(:order_endpoint) { "#{backend_url}/private/orders/taler-order-8" }
    let(:refund_endpoint) { "#{order_endpoint}/refund" }
    let(:taler_refund_uri) {
      "taler://refund/backend.demo.taler.net/instances/sandbox/taler-order-8/"
    }

    it "starts the refund process" do
      order_status = {
        order_status: "paid",
        contract_terms: {
          amount: "KUDOS:2",
        }
      }
      stub_request(:get, order_endpoint).to_return(body: order_status.to_json)
      stub_request(:post, refund_endpoint).to_return(body: { taler_refund_uri: }.to_json)
      order = create(:completed_order_with_totals)
      order.payments.create(
        amount: order.total, state: :completed,
        payment_method: taler,
        response_code: "taler-order-8",
      )
      expect {
        response = taler.void("taler-order-8", { payment: order.payments[0] })
        expect(response.success?).to eq true
      }.to enqueue_mail(PaymentMailer, :refund_available)
    end

    it "returns early if payment already void" do
      order_status = {
        order_status: "claimed",
      }
      stub_request(:get, order_endpoint).to_return(body: order_status.to_json)
      order = create(:completed_order_with_totals)
      order.payments.create(
        amount: order.total, state: :completed,
        payment_method: taler,
        response_code: "taler-order-8",
      )
      expect {
        response = taler.void("taler-order-8", { payment: order.payments[0] })
        expect(response.success?).to eq true
      }.not_to enqueue_mail
    end
  end
end
