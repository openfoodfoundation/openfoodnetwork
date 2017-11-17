require 'spec_helper'

describe "checking out an order with a paypal express payment method", type: :request do
  include ShopWorkflow

  let!(:address) { create(:address) }
  let!(:shop) { create(:enterprise) }
  let!(:shipping_method) { create(:shipping_method, distributor_ids: [shop.id]) }
  let!(:order) { create(:order, distributor: shop, ship_address: address.dup, bill_address: address.dup) }
  let!(:shipment) { create(:shipment, order: order, shipping_method: shipping_method) }
  let!(:line_item) { create(:line_item, order: order, quantity: 3, price: 5.00) }
  let!(:payment_method) { Spree::Gateway::PayPalExpress.create!(name: "PayPalExpress", distributor_ids: [create(:distributor_enterprise).id], environment: Rails.env) }
  let(:params) { { token: 'lalalala', PayerID: 'payer1', payment_method_id: payment_method.id } }
  let(:mocked_xml_response) {
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <Envelope><Body>
      <GetExpressCheckoutDetailsResponse>
        <Ack>Success</Ack>
        <PaymentDetails>Something</PaymentDetails>
        <DoExpressCheckoutPaymentResponseDetails>
          <PaymentInfo><TransactionID>s0metran$act10n</TransactionID></PaymentInfo>
        </DoExpressCheckoutPaymentResponseDetails>
      </GetExpressCheckoutDetailsResponse>
    </Body></Envelope>"
  }

  before do
    order.reload.update_totals
    order.shipping_method = shipping_method
    expect(order.next).to be true # => address
    expect(order.next).to be true # => delivery
    expect(order.next).to be true # => payment
    set_order order

    stub_request(:post, "https://api-3t.sandbox.paypal.com/2.0/")
      .to_return(:status => 200, :body => mocked_xml_response )
  end

  context "with a flat percent calculator" do
    let(:calculator) { Spree::Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 10) }

    before do
      payment_method.calculator = calculator
      payment_method.save!
      order.payments.create!(payment_method_id: payment_method.id, amount: order.total)
    end

    it "destroys the old payment and processes the order" do
      # Sanity check to condition of the order before we confirm the payment
      expect(order.payments.count).to eq 1
      expect(order.payments.first.state).to eq "checkout"
      expect(order.adjustments.payment_fee.count).to eq 1
      expect(order.adjustments.payment_fee.first.amount).to eq 1.5

      get spree.confirm_paypal_path, params

      # Processing was successful, order is complete
      expect(response).to redirect_to spree.order_path(order, :token => order.token)
      expect(order.reload.complete?).to be true

      # We have only one payment, and one transaction fee
      expect(order.payments.count).to eq 1
      expect(order.payments.first.state).to eq "completed"
      expect(order.adjustments.payment_fee.count).to eq 1
      expect(order.adjustments.payment_fee.first.amount).to eq 1.5
    end
  end
end
