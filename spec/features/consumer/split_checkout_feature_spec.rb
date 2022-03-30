# frozen_string_literal: true

require "spec_helper"

describe "As a consumer, I want to checkout my order", js: true, billy: true do
  include ShopWorkflow
  include SplitCheckoutHelper
  include FileHelper
  include StripeHelper
  include StripeStubs
  include PaypalHelper
  include AuthenticationHelper

  let!(:zone) { create(:zone_with_member) }
  let(:supplier) { create(:supplier_enterprise) }
  let(:distributor) { create(:distributor_enterprise, charges_sales_tax: true) }
  let(:product) {
    create(:taxed_product, supplier: supplier, price: 10, zone: zone, tax_rate_amount: 0.1)
  }
  let(:variant) { product.variants.first }
  let!(:order_cycle) {
    create(:simple_order_cycle, suppliers: [supplier], distributors: [distributor],
                                coordinator: create(:distributor_enterprise), variants: [variant])
  }
  let(:order) {
    create(:order, order_cycle: order_cycle, distributor: distributor, bill_address_id: nil,
                   ship_address_id: nil, state: "cart",
                   line_items: [create(:line_item, variant: variant)])
  }

  let(:fee_tax_rate) { create(:tax_rate, amount: 0.10, zone: zone, included_in_price: true) }
  let(:fee_tax_category) { create(:tax_category, tax_rates: [fee_tax_rate]) }
  let(:enterprise_fee) { create(:enterprise_fee, amount: 1.23, tax_category: fee_tax_category) }

  let(:free_shipping_with_required_address) {
    create(:shipping_method, require_ship_address: true, name: "A Free Shipping with required address")
  }
  let(:free_shipping) {
    create(:shipping_method, require_ship_address: false, name: "Free Shipping", description: "yellow",
                             calculator: Calculator::FlatRate.new(preferred_amount: 0.00))
  }
  let(:shipping_tax_rate) { create(:tax_rate, amount: 0.25, zone: zone, included_in_price: true) }
  let(:shipping_tax_category) { create(:tax_category, tax_rates: [shipping_tax_rate]) }
  let(:shipping_with_fee) {
    create(:shipping_method, require_ship_address: true, tax_category: shipping_tax_category,
                             name: "Shipping with Fee", description: "blue",
                             calculator: Calculator::FlatRate.new(preferred_amount: 4.56))
  }

  let!(:stripe_account) { create(:stripe_account, enterprise: distributor) }
  let!(:stripe_sca_payment_method) {
    create(:stripe_sca_payment_method, distributors: [distributor], name: "Stripe SCA")
  }
  let(:free_shipping_without_required_address) {
    create(:shipping_method, require_ship_address: false, name: "Z Free Shipping without required address")
  }

  let(:shipping_backoffice_only) {
    create(:shipping_method, require_ship_address: true, name: "Shipping Backoffice Only", display_on: "back_end")
  }

  before do
    allow(Flipper).to receive(:enabled?).with(:split_checkout).and_return(true)
    allow(Flipper).to receive(:enabled?).with(:split_checkout, anything).and_return(true)

    add_enterprise_fee enterprise_fee
    set_order order

    distributor.shipping_methods.push(free_shipping_with_required_address, free_shipping, shipping_with_fee, free_shipping_without_required_address)
  end

  context "as a logged in user" do
    let(:user) { create(:user) }

    before do
      login_as(user)
      visit checkout_path
    end

    context "payment step" do
      let(:order) { create(:order_ready_for_payment, distributor: distributor)}

      context "checking out with Stripe SCA" do
        before do
          setup_stripe
          visit checkout_step_path(:payment)
        end

        it "selects Stripe SCA and proceeds to payment step" do
          byebug
          choose stripe_sca_payment_method.name
          fill_out_card_details
          proceed_to_summary
        end

        #it " fills in card data and saves a Stripe card" do
        #end
      end
    end

  end

end
