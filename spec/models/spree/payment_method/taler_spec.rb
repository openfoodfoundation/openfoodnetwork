# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::PaymentMethod::Taler do
  subject(:taler) {
    Spree::PaymentMethod::Taler.new(
      preferred_backend_url: "https://backend.demo.taler.net/instances/sandbox",
      preferred_api_key: "sandbox",
    )
  }

  describe "external_payment_url", vcr: true do
    it "retrieves a URL to pay at and stores it on the payment record" do
      order = create(:order_ready_for_confirmation, payment_method: taler)
      url = subject.external_payment_url(order:)
      expect(url).to match %r{\Ahttps://backend.demo.taler.net/instances/sandb}

      payment = order.payments.last.reload
      expect(payment.response_code).to match "2026.022-0284X4GE8WKMJ"
      expect(payment.redirect_auth_url).to eq url
    end
  end
end
