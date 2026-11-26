# frozen_string_literal: true

RSpec.describe PaypalRest::OrderRequestBuilderService do
  let(:order) { create(:completed_order_with_fees) }
  let(:payment) { order.payments.first }
  let(:payment_method) { create(:paypal_rest_payment_method) }
  let(:request) {
    described_class.new(
      order:, payment:, payment_method:,
      return_url: 'https://ofn.example/return',
      cancel_url: 'https://ofn.example/cancel'
    ).call
  }
  let(:experience_context) { request.payment_source[:paypal][:experience_context] }

  before { order.update_order! }

  it "requests an immediate capture with one purchase unit" do
    expect(request.intent).to eq(PaypalServerSdk::CheckoutPaymentIntent::CAPTURE)
    expect(request.purchase_units.length).to eq(1)
    expect(request.purchase_units.first[:amount][:value]).to eq(format("%.2f", payment.amount))
  end

  it "sets the PayPal experience context" do
    expect(experience_context).to include(
      return_url: 'https://ofn.example/return',
      cancel_url: 'https://ofn.example/cancel',
      user_action: PaypalServerSdk::PaypalExperienceUserAction::PAY_NOW,
      shipping_preference: PaypalServerSdk::PaypalWalletContextShippingPreference::NO_SHIPPING
    )
  end

  context "when the payment method requires an address" do
    let(:payment_method) {
      create(:paypal_rest_payment_method, preferred_solution: "Sole")
    }

    it "sends the provided shipping address" do
      expect(experience_context[:shipping_preference]).to eq(
        PaypalServerSdk::PaypalWalletContextShippingPreference::SET_PROVIDED_ADDRESS
      )
      expect(request.purchase_units.first[:shipping]).to be_present
    end

    context "when the order has no shipping address" do
      before { allow(order).to receive(:ship_address).and_return(nil) }

      it "asks PayPal to collect the address" do
        expect(experience_context[:shipping_preference]).to eq(
          PaypalServerSdk::PaypalWalletContextShippingPreference::GET_FROM_FILE
        )
        expect(request.purchase_units.first).not_to have_key(:shipping)
      end
    end
  end
end
