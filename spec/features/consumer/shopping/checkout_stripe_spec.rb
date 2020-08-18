require 'spec_helper'

feature "As a consumer I want to check out my cart", js: true do
  include AuthenticationHelper
  include ShopWorkflow
  include CheckoutHelper
  include WebHelper
  include UIComponentHelper

  let!(:zone) { create(:zone_with_member) }
  let(:distributor) { create(:distributor_enterprise, charges_sales_tax: true) }
  let(:supplier) { create(:supplier_enterprise) }
  let!(:order_cycle) { create(:simple_order_cycle, suppliers: [supplier], distributors: [distributor], coordinator: create(:distributor_enterprise), variants: [variant]) }
  let(:enterprise_fee) { create(:enterprise_fee, amount: 1.23, tax_category: product.tax_category) }
  let(:product) { create(:taxed_product, supplier: supplier, price: 10, zone: zone, tax_rate_amount: 0.1) }
  let(:variant) { product.variants.first }
  let(:order) { create(:order, order_cycle: order_cycle, distributor: distributor, bill_address_id: nil, ship_address_id: nil) }

  let(:free_shipping) { create(:shipping_method, require_ship_address: true, name: "Frogs", description: "yellow", calculator: Calculator::FlatRate.new(preferred_amount: 0.00)) }
  let(:shipping_with_fee) { create(:shipping_method, require_ship_address: false, name: "Donkeys", description: "blue", calculator: Calculator::FlatRate.new(preferred_amount: 4.56)) }
  let(:tagged_shipping) { create(:shipping_method, require_ship_address: false, name: "Local", tag_list: "local") }
  let!(:check_without_fee) { create(:payment_method, distributors: [distributor], name: "Roger rabbit", type: "Spree::PaymentMethod::Check") }
  let!(:check_with_fee) { create(:payment_method, distributors: [distributor], calculator: Calculator::FlatRate.new(preferred_amount: 5.67)) }
  let!(:paypal) do
    Spree::Gateway::PayPalExpress.create!(name: "Paypal", environment: 'test', distributor_ids: [distributor.id]).tap do |pm|
      pm.preferred_login = 'devnull-facilitator_api1.rohanmitchell.com'
      pm.preferred_password = '1406163716'
      pm.preferred_signature = 'AFcWxV21C7fd0v3bYYYRCpSSRl31AaTntNJ-AjvUJkWf4dgJIvcLsf1V'
    end
  end

  before do
    Spree::Config.shipment_inc_vat = true
    Spree::Config.shipping_tax_rate = 0.25

    add_enterprise_fee enterprise_fee
    set_order order
    add_product_to_cart order, product

    distributor.shipping_methods << free_shipping
    distributor.shipping_methods << shipping_with_fee
    distributor.shipping_methods << tagged_shipping
  end

  context 'login in as user' do
    let(:user) { create(:user) }

    before do
      login_as(user)
    end

    context "with Stripe" do
      let!(:stripe_pm) do
        create(:stripe_payment_method, distributors: [distributor])
      end

      let!(:saved_card) do
        create(:credit_card,
               user_id: user.id,
               month: "01",
               year: "2025",
               cc_type: "visa",
               number: "1111111111111111",
               payment_method_id: stripe_pm.id,
               gateway_customer_profile_id: "i_am_saved")
      end

      let!(:stripe_account) { create(:stripe_account, enterprise_id: distributor.id, stripe_user_id: 'some_id') }

      let(:response_mock) { { id: "ch_1234", object: "charge", amount: 2000 } }

      before do
        allow(Stripe).to receive(:api_key) { "sk_test_12345" }
        allow(Stripe).to receive(:publishable_key) { "some_key" }
        Spree::Config.set(stripe_connect_enabled: true)
        stub_request(:post, "https://api.stripe.com/v1/charges")
          .with(basic_auth: ["sk_test_12345", ""])
          .to_return(status: 200, body: JSON.generate(response_mock))

        visit checkout_path
        fill_out_form(free_shipping.name, stripe_pm.name)
      end

      it "allows use of a saved card" do
        # shows the saved credit card dropdown
        expect(page).to have_content I18n.t("spree.checkout.payment.stripe.used_saved_card")

        # default card is selected, form element is not shown
        expect(page).to have_no_selector "#card-element.StripeElement"
        expect(page).to have_select 'selected_card', selected: "Visa x-1111 Exp:01/2025"

        # allows checkout
        place_order
        expect(page).to have_content "Your order has been processed successfully"
      end
    end
  end
end
