# frozen_string_literal: true

require 'spec_helper'

describe "checking out an order with a paypal express payment method", type: :request do
  include ShopWorkflow
  include PaypalHelper

  let!(:address) { create(:address) }
  let!(:shop) { create(:enterprise) }
  let!(:shipping_method) { create(:shipping_method_with, :distributor, distributor: shop) }
  let!(:shipment) { create(:shipment_with, :shipping_method, shipping_method: shipping_method) }
  let!(:order) do
    create(
      :order,
      distributor: shop,
      shipments: [shipment],
      ship_address: address.dup,
      bill_address: address.dup
    )
  end
  let!(:line_item) { create(:line_item, order: order, quantity: 3, price: 5.00) }
  let!(:payment_method) do
    Spree::Gateway::PayPalExpress.create!(
      name: "PayPalExpress",
      distributor_ids: [create(:distributor_enterprise).id],
      environment: Rails.env
    )
  end
  let(:params) { { token: 'lalalala', PayerID: 'payer1', payment_method_id: payment_method.id } }

  before do
    order.reload.update_totals
    expect(order.next).to be true # => address
    expect(order.next).to be true # => delivery
    expect(order.next).to be true # => payment
    set_order order

    stub_paypal_confirm
  end

  context "with a flat percent calculator" do
    let(:calculator) { Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 10) }

    before do
      payment_method.calculator = calculator
      payment_method.save!
      order.payments.create!(payment_method_id: payment_method.id, amount: order.total)
      order.next
    end

    it "destroys the old payment and processes the order" do
      # Sanity check to condition of the order before we confirm the payment
      expect(order.payments.count).to eq 1
      expect(order.payments.first.state).to eq "checkout"
      expect(order.all_adjustments.payment_fee.count).to eq 1
      expect(order.all_adjustments.payment_fee.first.amount).to eq 1.5

      get payment_gateways_confirm_paypal_path, params: params

      # Processing was successful, order is complete
      expect(response).to redirect_to order_path(order, order_token: order.token)
      expect(order.reload.complete?).to be true

      # We have only one payment, and one transaction fee
      expect(order.payments.count).to eq 1
      expect(order.payments.first.state).to eq "completed"
      expect(order.all_adjustments.payment_fee.count).to eq 1
      expect(order.all_adjustments.payment_fee.first.amount).to eq 1.5
    end
  end
end
