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

  describe "when I have an out of stock product in my cart" do
    before do
      variant.on_demand = false
      variant.on_hand = 0
      variant.save!
    end

    it "returns me to the cart with an error message" do
      visit checkout_path

      expect(page).not_to have_selector 'closing', text: "Checkout now"
      expect(page).to have_selector 'closing', text: "Your shopping cart"
      expect(page).to have_content "An item in your cart has become unavailable"
    end
  end

  context 'login in as user' do
    let(:user) { create(:user) }

    before do
      login_as(user)
    end

    context "with details filled out" do
      before do
        visit checkout_path
        fill_out_form(free_shipping.name, check_without_fee.name)
      end

      it "creates a new default billing address and shipping address" do
        expect(user.bill_address).to be_nil
        expect(user.ship_address).to be_nil

        expect(order.bill_address).to be_nil
        expect(order.ship_address).to be_nil

        place_order
        expect(page).to have_content "Your order has been processed successfully"

        expect(order.reload.bill_address.address1).to eq '123 Your Head'
        expect(order.reload.ship_address.address1).to eq '123 Your Head'

        expect(order.customer.bill_address.address1).to eq '123 Your Head'
        expect(order.customer.ship_address.address1).to eq '123 Your Head'

        expect(user.reload.bill_address.address1).to eq '123 Your Head'
        expect(user.reload.ship_address.address1).to eq '123 Your Head'
      end

      context "when the user and customer have existing default addresses" do
        let(:existing_address) { create(:address) }

        before do
          user.bill_address = existing_address
          user.ship_address = existing_address
        end

        it "updates billing address and shipping address" do
          expect(order.bill_address).to be_nil
          expect(order.ship_address).to be_nil

          place_order
          expect(page).to have_content "Your order has been processed successfully"

          expect(order.reload.bill_address.address1).to eq '123 Your Head'
          expect(order.reload.ship_address.address1).to eq '123 Your Head'

          expect(order.customer.bill_address.address1).to eq '123 Your Head'
          expect(order.customer.ship_address.address1).to eq '123 Your Head'

          expect(user.reload.bill_address.address1).to eq '123 Your Head'
          expect(user.reload.ship_address.address1).to eq '123 Your Head'
        end
      end

      it "doesn't tell about previous orders" do
        expect(page).to have_no_content("You have an order for this order cycle already.")
      end

      it "doesn't show link to terms and conditions" do
        expect(page).to have_no_link("Terms and Conditions")
      end
    end

    context "when distributor has T&Cs" do
      let(:fake_terms_and_conditions_path) { Rails.root.join("app/assets/images/logo-white.png") }
      let(:terms_and_conditions_file) { Rack::Test::UploadedFile.new(fake_terms_and_conditions_path, "application/pdf") }

      before do
        order.distributor.terms_and_conditions = terms_and_conditions_file
        order.distributor.save
      end

      describe "when customer has not accepted T&Cs before" do
        it "shows a link to the T&Cs and disables checkout button until terms are accepted" do
          visit checkout_path
          expect(page).to have_link("Terms and Conditions", href: order.distributor.terms_and_conditions.url)

          expect(page).to have_button("Place order now", disabled: true)

          check "accept_terms"
          expect(page).to have_button("Place order now", disabled: false)
        end
      end

      describe "when customer has already accepted T&Cs before" do
        before do
          customer = create(:customer, enterprise: order.distributor, user: user)
          customer.update terms_and_conditions_accepted_at: Time.zone.now
        end

        it "enables checkout button (because T&Cs are accepted by default)" do
          visit checkout_path
          expect(page).to have_button("Place order now", disabled: false)
        end

        describe "but afterwards the enterprise has uploaded a new T&Cs file" do
          before { order.distributor.update terms_and_conditions_updated_at: Time.zone.now }

          it "disables checkout button until terms are accepted" do
            visit checkout_path
            expect(page).to have_button("Place order now", disabled: true)
          end
        end
      end
    end

    context "with previous orders" do
      let!(:prev_order) { create(:completed_order_with_totals, order_cycle: order_cycle, distributor: distributor, user: order.user) }

      before do
        order.distributor.allow_order_changes = true
        order.distributor.save
        visit checkout_path
      end

      it "informs about previous orders" do
        expect(page).to have_content("You have an order for this order cycle already.")
      end
    end

    context "when the user has a preset shipping and billing address" do
      before do
        user.bill_address = build(:address)
        user.ship_address = build(:address)
        user.save!
      end

      it "checks out successfully" do
        visit checkout_path
        choose shipping_with_fee.name
        choose check_without_fee.name

        expect do
          place_order
          expect(page).to have_content "Your order has been processed successfully"
        end.to enqueue_job ConfirmOrderJob
      end
    end
  end
end
