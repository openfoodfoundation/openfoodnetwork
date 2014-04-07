require 'spec_helper'


feature "As a consumer I want to check out my cart", js: true do
  include AuthenticationWorkflow
  include ShopWorkflow
  include WebHelper

  let(:distributor) { create(:distributor_enterprise) }
  let(:supplier) { create(:supplier_enterprise) }
  let(:order_cycle) { create(:order_cycle, distributors: [distributor], coordinator: create(:distributor_enterprise)) }
  let(:product) { create(:simple_product, supplier: supplier) }
  let(:order) { Spree::Order.last }

  before do
    create_enterprise_group_for distributor
  end

  # Disabled :in for performance reasons
  [:out].each do |auth_state|
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
        it "shows all shipping methods, but doesn't show ship address when not needed" do
          page.should have_content "Frogs"
          page.should have_content "Donkeys"
          choose(sm2.name)
          find("#ship_address", visible: false).visible?.should be_false
        end

        context "When shipping method requires an address" do
          before do
            choose(sm1.name)
          end
          it "shows the hidden ship address fields by default" do
            check "Shipping address same as billing address?"
            find("#ship_address_hidden").visible?.should be_true
            find("#ship_address > div.visible", visible: false).visible?.should be_false

            # Check it keeps state
            click_button "Purchase"
            find_field("Shipping address same as billing address?").should be_checked
          end

          it "shows ship address forms when 'same as billing address' is unchecked" do
            uncheck "Shipping address same as billing address?"
            find("#ship_address_hidden", visible: false).visible?.should be_false
            find("#ship_address > div.visible").visible?.should be_true

            # Check it keeps state
            click_button "Purchase"
            find_field("Shipping address same as billing address?").should_not be_checked
          end
        end

        it "copies billing address to hidden shipping address fields" do
          choose(sm1.name)
          check "Shipping address same as billing address?"
          within "#billing" do
            fill_in "Address", with: "testy"
          end
          within "#ship_address_hidden" do
            find("#order_ship_address_attributes_address1", visible: false).value.should == "testy"
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
                fill_in "Address", with: "123 Your Face"
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
                fill_in "Address", with: "123 Your Face"
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
