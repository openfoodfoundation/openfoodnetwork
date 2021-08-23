# frozen_string_literal: true

require "spec_helper"

feature "Check out with Paypal", js: true do
  include ShopWorkflow
  include CheckoutRequestsHelper
  include AuthenticationHelper
  include PaypalHelper

  let(:distributor) { create(:distributor_enterprise) }
  let(:supplier) { create(:supplier_enterprise) }
  let(:product) { create(:simple_product, supplier: supplier) }
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
      order_cycle: order_cycle,
      distributor: distributor,
      bill_address_id: nil,
      ship_address_id: nil
    )
  }
  let(:free_shipping) { create(:shipping_method) }
  let!(:paypal) do
    Spree::Gateway::PayPalExpress.create!(
      name: "Paypal",
      environment: "test",
      distributor_ids: [distributor.id]
    )
  end
  let(:user) { create(:user) }

  before do
    distributor.shipping_methods << free_shipping
    set_order order
    add_product_to_cart order, product
  end

  context "as a guest" do
    it "fails with an error message" do
      visit checkout_path
      checkout_as_guest
      fill_out_form(free_shipping.name, paypal.name, save_default_addresses: false)

      stub_paypal_response success: false

      place_order
      expect(page).to have_content "PayPal failed."
    end
  end

  context "as a registered user" do
    before { login_as user }

    it "completes the checkout after successful Paypal payment" do
      visit checkout_path
      fill_out_details
      fill_out_form(free_shipping.name, paypal.name, save_default_addresses: false)

      # Normally the checkout would redirect to Paypal, a form would be filled out there, and the
      # user would be redirected back to #confirm_paypal_path. Here we skip the PayPal part and
      # jump straight to being redirected back to OFN with a "confirmed" payment.
      stub_paypal_response(
        success: true,
        redirect: spree.confirm_paypal_path(
          payment_method_id: paypal.id, token: "t123", PayerID: 'p123'
        )
      )
      stub_paypal_confirm

      place_order
      expect(page).to have_content "Your order has been processed successfully"

      expect(order.reload.state).to eq "complete"
      expect(order.payments.count).to eq 1
    end
  end
end
