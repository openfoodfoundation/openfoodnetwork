# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "/payment_gateways/taler/:id" do
  it "completes the order", :vcr do
    shop = create(:distributor_enterprise)
    taler = Spree::PaymentMethod::Taler.create!(
      name: "Taler",
      environment: "test",
      distributors: [shop],
      preferred_backend_url: "https://backend.demo.taler.net/instances/sandbox",
      preferred_api_key: "sandbox",
    )
    order = create(:order_ready_for_confirmation, payment_method: taler)
    payment = Spree::Payment.last
    payment.update!(
      source: taler,
      payment_method: taler,
      # This is a Taler order id of a paid order on the test backend.
      # It may be gone when you try to re-record this test.
      # To create a new order, you need user interaction with a wallet.
      response_code: "2026.020-03R3ETNZZ0DVA",
      redirect_auth_url: "https://merchant.backend.where-we-paid.com",
    )

    get payment_gateways_confirm_taler_path(payment_id: payment.id)
    expect(response).to redirect_to(order_path(order, order_token: order.token))

    payment.reload
    expect(payment.state).to eq "completed"
  end
end
