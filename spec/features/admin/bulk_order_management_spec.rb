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
      let!(:li1) { FactoryGirl.create(:line_item, order: o1 ) }
      let!(:li2) { FactoryGirl.create(:line_item, order: o2 ) }

      before :each do
        visit '/admin/orders/bulk_management'
      end

      it "displays a list of line items" do
        page.should have_selector "th.id", text: "ID", :visible => true
        page.should have_selector "td.id", text: li1.id.to_s, :visible => true
        page.should have_selector "td.id", text: li2.id.to_s, :visible => true
      end

      it "displays a column for user email" do
        page.should have_selector "th.email", text: "EMAIL", :visible => true
        page.should have_selector "td.email", text: o1.email, :visible => true
        page.should have_selector "td.email", text: o2.email, :visible => true
      end

      it "displays a column for order date" do
        page.should have_selector "th,date", text: "ORDER DATE", :visible => true
        page.should have_selector "td.date", text: o1.completed_at.strftime("%F %T"), :visible => true
        page.should have_selector "td.date", text: o2.completed_at.strftime("%F %T"), :visible => true
      end

      it "displays a column for producer" do
        page.should have_selector "th.producer", text: "PRODUCER", :visible => true
        page.should have_selector "td.producer", text: li1.product.supplier.name, :visible => true
        page.should have_selector "td.producer", text: li2.product.supplier.name, :visible => true
      end

      it "displays a column for variant description" do
        page.should have_selector "th.variant", text: "PRODUCT (UNIT): VAR", :visible => true
        page.should have_selector "td.variant", text: li1.product.name, :visible => true
        page.should have_selector "td.variant", text: li2.product.name, :visible => true
      end
    end
  end
end