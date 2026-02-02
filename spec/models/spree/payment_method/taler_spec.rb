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
end
