require 'spec_helper'


feature "As a consumer I want to check out my cart", js: true do
  include AuthenticationWorkflow
  include ShopWorkflow
  include WebHelper
  include UIComponentHelper

  let(:distributor) { create(:distributor_enterprise) }
  let(:supplier) { create(:supplier_enterprise) }
  let(:order_cycle) { create(:order_cycle, distributors: [distributor], coordinator: create(:distributor_enterprise)) }
  let(:product) { create(:simple_product, supplier: supplier) }
  let(:order) { Spree::Order.last }

  before do
    order_cycle # force this to load
    create_enterprise_group_for distributor
  end
  describe "Attempting to access checkout without meeting the preconditions" do
    it "redirects to the homepage if no distributor is selected" do
      visit "/shop/checkout"
      current_path.should == root_path
    end

    it "redirects to the shop page if we have a distributor but no order cycle selected" do
      select_distributor
      visit "/shop/checkout"
      current_path.should == shop_path
    end

    it "redirects to the shop page if the current order is empty" do
      select_distributor
      select_order_cycle
      visit "/shop/checkout"
      current_path.should == shop_path
    end

    it "renders checkout if we have distributor and order cycle selected" do
      select_distributor
      select_order_cycle
      add_product_to_cart
      visit "/shop/checkout"
      current_path.should == "/shop/checkout"
    end
  end
end
