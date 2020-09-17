require "spec_helper"

feature "Check out with Paypal", js: true do
  include ShopWorkflow
  include CheckoutHelper

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

  before do
    distributor.shipping_methods << free_shipping
    set_order order
    add_product_to_cart order, product
  end

  describe "as a guest" do
    it "fails with an error message" do
      visit checkout_path
      checkout_as_guest
      fill_out_form(free_shipping.name, paypal.name, save_default_addresses: false)

      paypal_response = double(:response, success?: false, errors: [])
      paypal_provider = double(
        :provider,
        build_set_express_checkout: nil,
        set_express_checkout: paypal_response
      )
      allow_any_instance_of(Spree::PaypalController).to receive(:provider).
        and_return(paypal_provider)

      place_order
      expect(page).to have_content "PayPal failed."
    end
  end
end
