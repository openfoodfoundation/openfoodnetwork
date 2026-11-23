# frozen_string_literal: true

require "system_helper"

RSpec.describe "Check out with PayPal REST" do
  include ShopWorkflow
  include AuthenticationHelper
  include CheckoutHelper

  let(:distributor) { create(:distributor_enterprise) }
  let(:supplier) { create(:supplier_enterprise) }
  let(:product) { create(:simple_product, enterprise_id: supplier.id) }
  let(:variant) { product.variants.first }
  let(:order_cycle) {
    create(
      :simple_order_cycle,
      suppliers: [supplier],
      distributors: [distributor],
      coordinator: distributor,
      variants: [variant]
    )
  }
  let(:order) {
    create(
      :order,
      order_cycle:,
      distributor:,
      bill_address_id: nil,
      ship_address_id: nil
    )
  }
  let(:free_shipping) { create(:shipping_method) }
  let!(:paypal) { create(:paypal_rest_payment_method, distributors: [distributor]) }
  let(:user) { create(:user) }
  let(:client) { instance_double(PaypalRest::Client) }

  before do
    distributor.shipping_methods << free_shipping
    login_as user
    pick_order order
    add_product_to_cart order, product

    allow(PaypalRest::Client).to receive(:new).and_return(client)
    allow(client).to receive(:create_order).and_return(
      PaypalRest::Result.new(
        success: true,
        order_id: 'ORDER-1',
        approval_url: payment_gateways_confirm_paypal_rest_path(
          payment_method_id: paypal.id, token: 'ORDER-1', PayerID: 'PAYER-1'
        ),
        status: 'CREATED'
      )
    )
    allow(client).to receive(:order_amount) do
      PaypalRest::Result.new(
        success: true, amount: format("%.2f", order.reload.total), currency_code: order.currency
      )
    end
    allow(client).to receive(:capture_order).and_return(
      PaypalRest::Result.new(
        success: true, order_id: 'ORDER-1', capture_id: 'CAPTURE-1',
        payer_id: 'PAYER-1', status: 'COMPLETED'
      )
    )
  end

  it "completes the order after returning from PayPal" do
    visit checkout_path
    fill_out_details
    fill_out_billing_address
    proceed_to_payment
    proceed_to_summary

    click_on "Complete order"

    expect(page).to have_content "Your order has been processed successfully"
    expect(order.reload.state).to eq "complete"
    expect(order.payments.first.source).to have_attributes(
      order_id: 'ORDER-1', capture_id: 'CAPTURE-1', payer_id: 'PAYER-1'
    )
  end
end
