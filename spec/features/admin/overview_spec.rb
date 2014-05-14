require 'spec_helper'

feature %q{
  As a backend user
  I want to be given information about the state of my enterprises, products and order cycles
} , js: true do
  include AuthenticationWorkflow
  include AuthorizationHelpers
  include WebHelper

  stub_authorization!

  context "as an enterprise user" do
    before :each do
      @enterprise_user = create_enterprise_user
      Spree::Admin::OverviewController.any_instance.stub(:spree_current_user).and_return @enterprise_user
      quick_login_as @enterprise_user
    end
    
    context "with no enterprises" do
      it "prompts the user to create a new enteprise" do
        visit '/admin'
        page.should have_selector ".dashboard_item#enterprises h3", text: "My Enterprises"
        page.should have_selector ".dashboard_item#enterprises .list-item", text: "You don't have any enterprises yet"
        page.should have_selector ".dashboard_item#enterprises .button.bottom", text: "CREATE A NEW ENTERPRISE"
        page.should_not have_selector ".dashboard_item#products"
        page.should_not have_selector ".dashboard_item#order_cycles"
      end
    end

    context "with an enterprise" do
      let(:d1) { create(:distributor_enterprise) }

      before :each do
        @enterprise_user.enterprise_roles.build(enterprise: d1).save
      end

      it "displays information about the enterprise" do
        visit '/admin'
        page.should have_selector ".dashboard_item#enterprises h3", text: "My Enterprises"
        page.should have_selector ".dashboard_item#products"
        page.should have_selector ".dashboard_item#order_cycles"
        page.should have_selector ".dashboard_item#enterprises .list-item", text: d1.name
        page.should have_selector ".dashboard_item#enterprises .button.bottom", text: "MANAGE MY ENTERPRISES"

      end
      
      context "but no products or order cycles" do
        it "prompts the user to create a new product and to manage order cycles" do
          visit '/admin'
          page.should have_selector ".dashboard_item#products h3", text: "Products"
          page.should have_selector ".dashboard_item#products .list-item", text: "You don't have any active products."
          page.should have_selector ".dashboard_item#products .button.bottom", text: "CREATE A NEW PRODUCT"
          page.should have_selector ".dashboard_item#order_cycles h3", text: "Order Cycles"
          page.should have_selector ".dashboard_item#order_cycles .list-item", text: "You don't have any active order cycles."
          page.should have_selector ".dashboard_item#order_cycles .button.bottom", text: "MANAGE ORDER CYCLES"
        end
      end

      context "and at least one product and active order cycle" do
        let(:oc1) { create(:simple_order_cycle, distributors: [d1]) }
        let(:p1) { create(:product, distributor: d1) }

        it "displays information about products and order cycles" do
          visit '/admin'
          page.should have_selector ".dashboard_item#products h3", text: "Products"
          page.should have_selector ".dashboard_item#products .list-item", text: "You don't have any active products."
          page.should have_selector ".dashboard_item#products .button.bottom", text: "CREATE A NEW PRODUCT"
          page.should have_selector ".dashboard_item#order_cycles h3", text: "Order Cycles"
          page.should have_selector ".dashboard_item#order_cycles .list-item", text: "You don't have any active order cycles."
          page.should have_selector ".dashboard_item#order_cycles .button.bottom", text: "MANAGE ORDER CYCLES"
        end
      end
    end
  end
end