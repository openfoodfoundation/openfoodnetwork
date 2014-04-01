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
    exchange = Exchange.find(order_cycle.exchanges.to_enterprises(distributor).outgoing.first.id) 
    exchange.variants << product.master
  end

  describe "Login behaviour" do
    let(:user) { create_enterprise_user }
    before do
      select_distributor
      select_order_cycle
      add_product_to_cart
    end

    it "renders the login form if user is logged out" do
      visit "/shop/checkout"
      within "section[role='main']" do
        page.should have_content "I HAVE AN OFN ACCOUNT"
      end
    end

    it "does not not render the login form if user is logged in" do
      login_to_consumer_section
      visit "/shop/checkout"
      within "section[role='main']" do
        page.should_not have_content "I HAVE AN OFN ACCOUNT"
      end
    end

    it "renders the signup link if user is logged out" do
      visit "/shop/checkout"
      within "section[role='main']" do
        page.should have_content "NEW TO OFN"
      end
    end

    it "does not not render the signup form if user is logged in" do
      login_to_consumer_section
      visit "/shop/checkout"
      within "section[role='main']" do
        page.should_not have_content "NEW TO OFN"
      end
    end

    it "redirects to the checkout page when logging in from the checkout page" do
      visit "/shop/checkout"
      within "#checkout_login" do
        fill_in "spree_user[email]", with: user.email 
        fill_in "spree_user[password]", with: user.password 
        click_button "Login"
      end

      current_path.should == "/shop/checkout"
      within "section[role='main']" do
        page.should_not have_content "I have an OFN Account"
      end
    end

    it "redirects to the checkout page when signing up from the checkout page" do
      visit "/shop/checkout"
      within "#checkout_signup" do
        fill_in "spree_user[email]", with: "test@gmail.com" 
        fill_in "spree_user[password]", with: "password" 
        fill_in "spree_user[password_confirmation]", with: "password" 
        click_button "Sign Up"
      end
      current_path.should == "/shop/checkout"
      within "section[role='main']" do
        page.should_not have_content "Sign Up"
      end
    end
  end
end
