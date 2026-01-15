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
    it "retrieves a URL to pay at" do
      url = subject.external_payment_url(order: nil)
      expect(url).to match %r{\Ahttps://backend.demo.taler.net/instances/sandb}
    end
  end
end
