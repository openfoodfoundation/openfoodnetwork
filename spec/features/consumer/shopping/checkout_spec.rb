require 'spec_helper'


feature "As a consumer I want to check out my cart", js: true do
  include AuthenticationWorkflow
  include ShopWorkflow
  include WebHelper
  include UIComponentHelper

  let(:distributor) { create(:distributor_enterprise) }
  let(:supplier) { create(:supplier_enterprise) }
  let!(:order_cycle) { create(:simple_order_cycle, distributors: [distributor], coordinator: create(:distributor_enterprise)) }
  let(:product) { create(:simple_product, supplier: supplier) }
  let(:order) { create(:order, order_cycle: order_cycle, distributor: distributor) }

  before do
    set_order order
    add_product_to_cart
  end

  it "shows the current distributor oncheckout" do
    visit checkout_path 
    page.should have_content distributor.name
  end

  describe "with shipping methods" do
    let(:sm1) { create(:shipping_method, require_ship_address: true, name: "Frogs", description: "yellow") }
    let(:sm2) { create(:shipping_method, require_ship_address: false, name: "Donkeys", description: "blue") }
    before do
      distributor.shipping_methods << sm1 
      distributor.shipping_methods << sm2 
    end

    context "on the checkout page" do
      before do
        visit checkout_path
      end

      it "shows all shipping methods, but doesn't show ship address when not needed" do
        toggle_accordion "Shipping"
        page.should have_content "Frogs"
        page.should have_content "Donkeys"
      end

      context "When shipping method requires an address" do
        before do
          toggle_accordion "Shipping"
          find(:radio_button, sm1.name, {}).trigger "click"
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
      let!(:pm3) { create(:payment_method, distributors: [distributor], name: "Paypal", type: "Spree::BillingIntegration::PaypalExpress") }

      before do
        visit checkout_path
        toggle_accordion "Payment Details"
      end

      it "shows all available payment methods" do
        page.should have_content pm1.name
        page.should have_content pm2.name
      end

      describe "Purchasing" do
        it "takes us to the order confirmation page when we submit a complete form" do
          ActionMailer::Base.deliveries.clear
          toggle_accordion "Shipping"
          choose sm2.name
          toggle_accordion "Payment Details"
          choose pm1.name
          toggle_accordion "Customer Details"
          within "#details" do
            fill_in "First Name", with: "Will"
            fill_in "Last Name", with: "Marshall"
            fill_in "Email", with: "test@test.com"
            fill_in "Phone", with: "0468363090"
          end
          toggle_accordion "Billing"
          within "#billing" do
            fill_in "Address", with: "123 Your Face"
            select "Australia", from: "Country"
            select "Victoria", from: "State"
            fill_in "City", with: "Melbourne"
            fill_in "Postcode", with: "3066"

          end
          click_button "Purchase"
          page.should have_content "Your order has been processed successfully", wait: 10
          ActionMailer::Base.deliveries.length.should == 1
          email = ActionMailer::Base.deliveries.last
          site_name = Spree::Config[:site_name]
          email.subject.should include "#{site_name} Order Confirmation"
        end

        it "takes us to the order confirmation page when submitted with 'same as billing address' checked" do
          toggle_accordion "Shipping"
          choose sm1.name
          toggle_accordion "Payment Details"
          choose pm1.name
          toggle_accordion "Customer Details"
          within "#details" do
            fill_in "First Name", with: "Will"
            fill_in "Last Name", with: "Marshall"
            fill_in "Email", with: "test@test.com"
            fill_in "Phone", with: "0468363090"
          end
          toggle_accordion "Billing"
          within "#billing" do
            fill_in "City", with: "Melbourne"
            fill_in "Postcode", with: "3066"
            fill_in "Address", with: "123 Your Face"
            select "Australia", from: "Country"
            select "Victoria", from: "State"
          end
          toggle_accordion "Shipping"
          check "Shipping address same as billing address?"
          click_button "Purchase"
          page.should have_content "Your order has been processed successfully", wait: 10
        end
      end
    end
  end
end
