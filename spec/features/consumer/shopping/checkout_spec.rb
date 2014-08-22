require 'spec_helper'


feature "As a consumer I want to check out my cart", js: true do
  include AuthenticationWorkflow
  include ShopWorkflow
  include CheckoutWorkflow
  include WebHelper
  include UIComponentHelper

  let(:distributor) { create(:distributor_enterprise) }
  let(:supplier) { create(:supplier_enterprise) }
  let!(:order_cycle) { create(:simple_order_cycle, suppliers: [supplier], distributors: [distributor], coordinator: create(:distributor_enterprise), variants: [product.master]) }
  let(:enterprise_fee) { create(:enterprise_fee, amount: 1.23) }
  let(:product) { create(:simple_product, supplier: supplier) }
  let(:order) { create(:order, order_cycle: order_cycle, distributor: distributor) }

  before do
    ActionMailer::Base.deliveries.clear
    add_enterprise_fee enterprise_fee
    set_order order
    add_product_to_cart
  end

  it "shows the current distributor on checkout" do
    visit checkout_path 
    page.should have_content distributor.name
  end

  describe "with shipping methods" do
    let(:sm1) { create(:shipping_method, require_ship_address: true, name: "Frogs", description: "yellow") }
    let(:sm2) { create(:shipping_method, require_ship_address: false, name: "Donkeys", description: "blue", calculator: Spree::Calculator::FlatRate.new(preferred_amount: 4.56)) }
    before do
      distributor.shipping_methods << sm1
      distributor.shipping_methods << sm2
    end

    context "on the checkout page" do
      before do
        visit checkout_path
        checkout_as_guest
      end

      it "shows a breakdown of the order price" do
        toggle_shipping
        choose sm2.name

        page.should have_selector 'orderdetails .cart-total', text: "$11.23"
        page.should have_selector 'orderdetails .shipping', text: "$4.56"
        page.should have_selector 'orderdetails .total', text: "$15.79"
      end

      it "shows all shipping methods, but doesn't show ship address when not needed" do
        toggle_shipping
        page.should have_content "Frogs"
        page.should have_content "Donkeys"
      end

      context "when shipping method requires an address" do
        before do
          toggle_shipping
          choose sm1.name
        end
        it "shows ship address forms when 'same as billing address' is unchecked" do
          uncheck "Shipping address same as billing address?"
          find("#ship_address > div.visible").visible?.should be_true
        end
      end
    end

    describe "with payment methods" do
      let!(:pm1) { create(:payment_method, distributors: [distributor], name: "Roger rabbit", type: "Spree::PaymentMethod::Check") }
      let!(:pm2) { create(:payment_method, distributors: [distributor]) }
      let!(:pm3) do
        Spree::Gateway::PayPalExpress.create!(name: "Paypal", environment: 'test', distributor_ids: [distributor.id]).tap do |pm|
          pm.preferred_login = 'devnull-facilitator_api1.rohanmitchell.com'
          pm.preferred_password = '1406163716'
          pm.preferred_signature = 'AFcWxV21C7fd0v3bYYYRCpSSRl31AaTntNJ-AjvUJkWf4dgJIvcLsf1V'
        end
      end

      context "on the checkout page with payments open" do
        before do
          visit checkout_path
          checkout_as_guest
          toggle_payment
        end

        it "shows all available payment methods" do
          page.should have_content pm1.name
          page.should have_content pm2.name
          page.should have_content pm3.name
        end

        describe "purchasing" do
          it "takes us to the order confirmation page when we submit a complete form" do
            toggle_shipping
            choose sm2.name
            toggle_payment
            choose pm1.name
            toggle_details
            within "#details" do
              fill_in "First Name", with: "Will"
              fill_in "Last Name", with: "Marshall"
              fill_in "Email", with: "test@test.com"
              fill_in "Phone", with: "0468363090"
            end
            toggle_billing
            within "#billing" do
              fill_in "Address", with: "123 Your Face"
              select "Australia", from: "Country"
              select "Victoria", from: "State"
              fill_in "City", with: "Melbourne"
              fill_in "Postcode", with: "3066"

            end
            place_order
            page.should have_content "Your order has been processed successfully"
            ActionMailer::Base.deliveries.length.should == 2
            email = ActionMailer::Base.deliveries.last
            site_name = Spree::Config[:site_name]
            email.subject.should include "#{site_name} Order Confirmation"
          end

          context "with basic details filled" do
            before do
              toggle_shipping
              choose sm1.name
              toggle_payment
              choose pm1.name
              toggle_details
              within "#details" do
                fill_in "First Name", with: "Will"
                fill_in "Last Name", with: "Marshall"
                fill_in "Email", with: "test@test.com"
                fill_in "Phone", with: "0468363090"
              end
              toggle_billing
              within "#billing" do
                fill_in "City", with: "Melbourne"
                fill_in "Postcode", with: "3066"
                fill_in "Address", with: "123 Your Face"
                select "Australia", from: "Country"
                select "Victoria", from: "State"
              end
              toggle_shipping
              check "Shipping address same as billing address?"
            end

            it "takes us to the order confirmation page when submitted with 'same as billing address' checked" do
              place_order
              page.should have_content "Your order has been processed successfully"
            end

            context "with a credit card payment method" do
              let!(:pm1) { create(:payment_method, distributors: [distributor], name: "Roger rabbit", type: "Spree::Gateway::Bogus") }

              it "takes us to the order confirmation page when submitted with a valid credit card" do
                toggle_payment
                fill_in 'Card Number', with: "4111111111111111"
                select 'February', from: 'secrets.card_month'
                select (Date.today.year+1).to_s, from: 'secrets.card_year'
                fill_in 'Security Code', with: '123'

                place_order
                page.should have_content "Your order has been processed successfully"

                # Order should have a payment with the correct amount
                o = Spree::Order.complete.first
                o.payments.first.amount.should == 11.23
              end

              it "shows the payment processing failed message when submitted with an invalid credit card" do
                toggle_payment
                fill_in 'Card Number', with: "9999999988887777"
                select 'February', from: 'secrets.card_month'
                select (Date.today.year+1).to_s, from: 'secrets.card_year'
                fill_in 'Security Code', with: '123'

                place_order
                page.should have_content "Payment could not be processed, please check the details you entered"

                # Does not show duplicate shipping fee
                visit checkout_path
                page.all("th", text: "Shipping").count.should == 1
              end
            end
          end
        end
      end

      context "when the customer has a pre-set shipping and billing address" do
        before do
          # Load up the customer's order and give them a shipping and billing address
          # This is equivalent to when the customer has ordered before and their addresses
          # are pre-populated.
          o = Spree::Order.last
          o.ship_address = build(:address)
          o.bill_address = build(:address)
          o.save!
        end

        it "checks out successfully" do
          visit checkout_path
          checkout_as_guest
          choose sm2.name
          toggle_payment
          choose pm1.name

          place_order
          page.should have_content "Your order has been processed successfully"
          ActionMailer::Base.deliveries.length.should == 2
        end
      end
    end
  end
end
