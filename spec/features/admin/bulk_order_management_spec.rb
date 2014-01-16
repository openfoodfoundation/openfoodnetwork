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

  describe "listing orders" do
    before :each do
      login_to_admin_section
    end
    
    it "displays a Bulk Management Tab under the Orders item" do
      visit '/admin/orders'

      page.should have_link "Bulk Order Management"
      click_link "Bulk Order Management"
      page.should have_selector "h1.page-title", text: "Bulk Order Management"
    end
  end
end