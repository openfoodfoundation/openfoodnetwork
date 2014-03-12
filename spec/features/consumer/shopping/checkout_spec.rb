require 'spec_helper'


feature "As a consumer I want to check out my cart", js: true do
  include AuthenticationWorkflow
  include WebHelper

  let(:distributor) { create(:distributor_enterprise) }
  let(:supplier) { create(:supplier_enterprise) }
  let(:order_cycle) { create(:order_cycle, distributors: [distributor], coordinator: create(:distributor_enterprise)) }
  let(:product) { create(:simple_product, supplier: supplier) }

  before do
    create_enterprise_group_for distributor
    exchange = Exchange.find(order_cycle.exchanges.to_enterprises(distributor).outgoing.first.id) 
    exchange.variants << product.master
  end

  # Run these tests both logged in and logged out!
  [:in, :out].each do |auth_state|
    describe "logged #{auth_state.to_s}, distributor selected, order cycle selected, product in cart" do
      let(:user) { create_enterprise_user }
      before do
        if auth_state == :in
          login_to_consumer_section
        end
        select_distributor
        select_order_cycle
        add_product_to_cart
      end

      describe "with shipping methods" do
        let(:sm1) { create(:shipping_method, require_ship_address: true, name: "Frogs", description: "yellow") }
        let(:sm2) { create(:shipping_method, require_ship_address: false, name: "Donkeys", description: "blue") }
        before do
          distributor.shipping_methods << sm1 
          distributor.shipping_methods << sm2 
          visit "/shop/checkout"
        end
        it "shows all shipping methods" do
          page.should have_content "Frogs"
          page.should have_content "Donkeys"
        end

        it "doesn't show ship address forms when a shipping method wants no address" do
          choose(sm2.name)
          find("#ship_address").visible?.should be_false
        end

        context "When shipping method requires an address" do
          before do
            choose(sm1.name)
          end
          it "shows the hidden ship address fields by default" do
            check "Shipping address same as billing address?"
            find("#ship_address_hidden").visible?.should be_true
            find("#ship_address > div.visible").visible?.should be_false

            # Check it keeps state
            click_button "Purchase"
            find_field("Shipping address same as billing address?").should be_checked
          end

          it "shows ship address forms when 'same as billing address' is unchecked" do
            uncheck "Shipping address same as billing address?"
            find("#ship_address_hidden").visible?.should be_false
            find("#ship_address > div.visible").visible?.should be_true

            # Check it keeps state
            click_button "Purchase"
            find_field("Shipping address same as billing address?").should_not be_checked
          end
        end

        it "copies billing address to hidden shipping address fields" do
          choose(sm1.name)
          check "Shipping address same as billing address?"
          fill_in "Billing Address", with: "testy"
          within "#ship_address_hidden" do
            find("#order_ship_address_attributes_address1").value.should == "testy"
          end
        end

        describe "with payment methods" do
          let(:pm1) { create(:payment_method, distributors: [distributor], name: "Roger rabbit", type: "Spree::PaymentMethod::Check") }
          let(:pm2) { create(:payment_method, distributors: [distributor]) }
          let(:pm3) { create(:payment_method, distributors: [distributor], name: "Paypal", type: "Spree::BillingIntegration::PaypalExpress") }

          before do
            pm1 # Lazy evaluation of ze create()s
            pm2
            visit "/shop/checkout"
          end

          it "shows all available payment methods" do
            page.should have_content pm1.name
            page.should have_content pm2.name
          end

          describe "Purchasing" do
            it "re-renders with errors when we submit the incomplete form" do
              choose sm2.name
              click_button "Purchase"
              current_path.should == "/shop/checkout"
              page.should have_content "can't be blank"
            end

            it "renders errors on the shipping method where appropriate"

            it "takes us to the order confirmation page when we submit a complete form" do
              choose sm2.name
              choose pm1.name
              within "#details" do
                fill_in "First Name", with: "Will"
                fill_in "Last Name", with: "Marshall"
                fill_in "Billing Address", with: "123 Your Face"
                select "Australia", from: "Country"
                select "Victoria", from: "State"
                fill_in "Customer E-Mail", with: "test@test.com"
                fill_in "Phone", with: "0468363090"
                fill_in "City", with: "Melbourne"
                fill_in "Postcode", with: "3066"
              end
              click_button "Purchase"
              page.should have_content "Your order has been processed successfully"
            end

            it "takes us to the order confirmation page when submitted with 'same as billing address' checked" do
              choose sm1.name
              choose pm1.name
              within "#details" do
                fill_in "First Name", with: "Will"
                fill_in "Last Name", with: "Marshall"
                fill_in "Billing Address", with: "123 Your Face"
                select "Australia", from: "Country"
                select "Victoria", from: "State"
                fill_in "Customer E-Mail", with: "test@test.com"
                fill_in "Phone", with: "0468363090"
                fill_in "City", with: "Melbourne"
                fill_in "Postcode", with: "3066"
              end
              check "Shipping address same as billing address?"
              click_button "Purchase"
              page.should have_content "Your order has been processed successfully"
            end
          end
        end
      end
    end
    
  end
end

def select_distributor
  visit "/"
  click_link distributor.name
end

def select_order_cycle
  exchange = Exchange.find(order_cycle.exchanges.to_enterprises(distributor).outgoing.first.id) 
  visit "/shop"
  select exchange.pickup_time, from: "order_cycle_id"
end

def add_product_to_cart

  fill_in "variants[#{product.master.id}]", with: 5
  first("form.custom > input.button.right").click 
end
