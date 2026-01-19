# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "/payment_gateways/taler/:id" do
  it "completes the order" do
    shop = create(:distributor_enterprise)
    taler = Spree::PaymentMethod::Taler.create!(
      name: "Taler",
      environment: "test",
      distributors: [shop],
    )
    order = create(:order_ready_for_confirmation, payment_method: taler)
    payment = Spree::Payment.last
    payment.update!(
      payment_method: taler,
      response_code: "taler-order-id:12345",
      redirect_auth_url: "https://merchant.backend.where-we-paid.com",
    )

    get payment_gateways_confirm_taler_path(payment_id: payment.id)
    expect(response).to redirect_to(order_path(order, order_token: order.token))

    payment.reload
    expect(payment.state).to eq "completed"
  end
end
