require 'spec_helper'

feature %q{
    As an administrator
    I want to manage order cycles
}, js: true do
  include AuthenticationWorkflow
  include WebHelper

  scenario "listing order cycles" do
    oc = create(:order_cycle)

    login_to_admin_section
    click_link 'Order Cycles'

    # Regular fields
    page.should have_selector 'a', text: oc.name

    page.should have_selector "input[value='#{oc.orders_open_at}']"
    page.should have_selector "input[value='#{oc.orders_close_at}']"
    page.should have_content oc.coordinator.name

    # Suppliers and distributors
    oc.suppliers.each    { |s| page.should have_content s.name }
    oc.distributors.each { |d| page.should have_content d.name }

    # Products
    all('td.products img').count.should == 2
  end

end
