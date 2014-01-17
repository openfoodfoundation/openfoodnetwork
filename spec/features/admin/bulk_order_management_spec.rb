require 'spec_helper'

feature %q{
  As an Administrator
  I want to be able to manage orders in bulk
} , js: true do
  include AuthenticationWorkflow
  include WebHelper

  before :all do
    @default_wait_time = Capybara.default_wait_time
    Capybara.default_wait_time = 5
  end

  after :all do
    Capybara.default_wait_time = @default_wait_time
  end

  context "listing orders" do
    before :each do
      login_to_admin_section
    end

    it "displays a Bulk Management Tab under the Orders item" do
      visit '/admin/orders'

      page.should have_link "Bulk Order Management"
      click_link "Bulk Order Management"
      page.should have_selector "h1.page-title", text: "Bulk Order Management"
    end

    context "displaying individual columns" do
      let!(:o1) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.now ) }
      let!(:o2) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.now ) }

      before :each do
        visit '/admin/orders/bulk_management'
      end

      it "displays a list of orders" do
        page.should have_selector "th", text: "ID", :visible => true
        page.should have_selector "td", text: o1.id.to_s, :visible => true
        page.should have_selector "td", text: o2.id.to_s, :visible => true
      end

      it "displays a column for user email" do
        page.should have_selector "th", text: "EMAIL", :visible => true
        page.should have_selector "td", text: o1.email, :visible => true
        page.should have_selector "td", text: o2.email, :visible => true
      end

      it "displays a column for order date" do
        page.should have_selector "th", text: "ORDER DATE", :visible => true
        page.should have_selector "td", text: o1.completed_at.strftime("%F %T"), :visible => true
        page.should have_selector "td", text: o2.completed_at.strftime("%F %T"), :visible => true
      end
    end
  end
end