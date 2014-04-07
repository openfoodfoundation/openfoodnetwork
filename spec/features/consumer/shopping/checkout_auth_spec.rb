require 'spec_helper'

feature "As a consumer I want to check out my cart", js: true do
  include AuthenticationWorkflow
  include WebHelper
  include ShopWorkflow

  let(:distributor) { create(:distributor_enterprise) }
  let(:supplier) { create(:supplier_enterprise) }
  let(:order_cycle) { create(:order_cycle, distributors: [distributor], coordinator: create(:distributor_enterprise)) }
  let(:product) { create(:simple_product, supplier: supplier) }
  let(:order) { Spree::Order.last }

  before do
    create_enterprise_group_for distributor
  end

  describe "Login behaviour" do
    let(:user) { create_enterprise_user }
    before do
      select_distributor
      select_order_cycle
      add_product_to_cart
    end


    context "logged in" do
      before do
        login_to_consumer_section
        visit "/shop/checkout"
      end
      it "does not not render the login form" do
        within "section[role='main']" do
          page.should_not have_content "USER"
        end
      end
    end

    context "logged out" do
      before do
        visit "/shop/checkout"
        save_and_open_page
        toggle_accordion "User"
      end

      it "renders the login form if user is logged out" do
        within "section[role='main']" do
          page.should have_content "USER"
        end
      end
    end
  end
end
