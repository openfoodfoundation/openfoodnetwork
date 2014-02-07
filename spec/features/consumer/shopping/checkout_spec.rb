require 'spec_helper'

include AuthenticationWorkflow
include WebHelper

feature "As a consumer I want to check out my cart", js: true do
  let(:distributor) { create(:distributor_enterprise) }
  let(:order_cycle) { create(:order_cycle, distributors: [distributor], coordinator: create(:distributor_enterprise)) }

  before do
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


    it "renders checkout if we have distributor and order cycle selected" do
      select_distributor
      select_order_cycle
      visit "/shop/checkout"
      current_path.should == "/shop/checkout"
    end
  end

  describe "Login behaviour" do
    before do
      select_distributor
      select_order_cycle
    end

    it "renders the login form if user is logged out" do
      visit "/shop/checkout"
      within "section[role='main']" do
        page.should have_content "Login"
      end
    end

    it "does not not render the login form if user is logged in" do
      login_to_consumer_section
      visit "/shop/checkout"
      within "section[role='main']" do
        page.should_not have_content "Login"
      end
    end

    it "renders the signup link if user is logged out" do
      visit "/shop/checkout"
      within "section[role='main']" do
        page.should have_content "Sign Up"
      end
    end

    it "does not not render the signup form if user is logged in" do
      login_to_consumer_section
      visit "/shop/checkout"
      within "section[role='main']" do
        page.should_not have_content "Sign Up"
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
