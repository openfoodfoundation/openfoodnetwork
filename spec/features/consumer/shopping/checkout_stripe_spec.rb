require 'spec_helper'

feature "Check out with Stripe", js: true do
  include AuthenticationHelper
  include ShopWorkflow
  include CheckoutHelper

  let(:distributor) { create(:distributor_enterprise) }
  let!(:order_cycle) { create(:simple_order_cycle, distributors: [distributor], variants: [variant]) }
  let(:product) { create(:product, price: 10) }
  let(:variant) { product.variants.first }
  let(:order) { create(:order, order_cycle: order_cycle, distributor: distributor, bill_address_id: nil, ship_address_id: nil) }

  let(:shipping_with_fee) { create(:shipping_method, require_ship_address: false, name: "Donkeys", calculator: Calculator::FlatRate.new(preferred_amount: 4.56)) }
  let!(:check_with_fee) { create(:payment_method, distributors: [distributor], calculator: Calculator::FlatRate.new(preferred_amount: 5.67)) }

  before do
    set_order order
    add_product_to_cart order, product
    distributor.shipping_methods << shipping_with_fee
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

      around do |example|
        original_stripe_connect_enabled = Spree::Config[:stripe_connect_enabled]
        example.run
        Spree::Config.set(stripe_connect_enabled: original_stripe_connect_enabled)
      end

      before do
        allow(Stripe).to receive(:api_key) { "sk_test_12345" }
        allow(Stripe).to receive(:publishable_key) { "some_key" }
        Spree::Config.set(stripe_connect_enabled: true)
        stub_request(:post, "https://api.stripe.com/v1/charges")
          .with(basic_auth: ["sk_test_12345", ""])
          .to_return(status: 200, body: JSON.generate(response_mock))

        visit checkout_path
        fill_out_form(shipping_with_fee.name, stripe_pm.name, save_default_addresses: false)
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
