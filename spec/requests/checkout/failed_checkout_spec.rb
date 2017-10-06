require 'spec_helper'

describe "checking out an order that initially fails", type: :request do
  include ShopWorkflow

  let!(:shop) { create(:enterprise) }
  let!(:order_cycle) { create(:simple_order_cycle) }
  let!(:exchange) { create(:exchange, order_cycle: order_cycle, sender: order_cycle.coordinator, receiver: shop, incoming: false, pickup_time: "Monday") }
  let!(:address) { create(:address) }
  let!(:order) { create(:order, distributor: shop, order_cycle: order_cycle) }
  let!(:line_item) { create(:line_item, order: order, quantity: 3, price: 5.00) }
  let!(:payment_method) { create(:bogus_payment_method, distributor_ids: [shop.id], environment: Rails.env) }
  let!(:check_payment_method) { create(:payment_method, distributor_ids: [shop.id], environment: Rails.env) }
  let!(:shipping_method) { create(:shipping_method, distributor_ids: [shop.id]) }
  let!(:shipment) { create(:shipment, order: order, shipping_method: shipping_method) }
  let(:params) do
    { format: :json, order: {
      shipping_method_id: shipping_method.id,
      payments_attributes: [{payment_method_id: payment_method.id}],
      bill_address_attributes: address.attributes.slice("firstname", "lastname", "address1", "address2", "phone", "city", "zipcode", "state_id", "country_id"),
      ship_address_attributes: address.attributes.slice("firstname", "lastname", "address1", "address2", "phone", "city", "zipcode", "state_id", "country_id")
    } }
  end

  before do
    order.reload.update_totals
    set_order order
  end

  context "when shipping and payment fees apply" do
    let(:calculator) { Spree::Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 10) }

    before do
      payment_method.calculator = calculator.dup
      payment_method.save!
      check_payment_method.calculator = calculator.dup
      check_payment_method.save!
      shipping_method.calculator = calculator.dup
      shipping_method.save!
    end

    it "clears shipments and payments before rendering the checkout" do
      put update_checkout_path, params

      # Checking out a BogusGateway without a source fails at :payment
      # Shipments and payments should then be cleared before rendering checkout
      expect(response.status).to be 400
      expect(flash[:error]).to eq I18n.t(:payment_processing_failed)
      order.reload
      expect(order.shipments.count).to be 0
      expect(order.payments.count).to be 0
      expect(order.adjustment_total).to eq 0

      # Add another line item to change the fee totals
      create(:line_item, order: order, quantity: 3, price: 5.00)

      # Use a check payment method, which should work
      params[:order][:payments_attributes][0][:payment_method_id] = check_payment_method.id
      put update_checkout_path, params

      expect(response.status).to be 200
      order.reload
      expect(order.total).to eq 36
      expect(order.adjustment_total).to eq 6
      expect(order.item_total).to eq 30
      expect(order.shipments.count).to eq 1
      expect(order.payments.count).to eq 1
    end
  end
end
