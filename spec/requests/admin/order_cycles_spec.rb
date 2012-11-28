require 'spec_helper'

feature %q{
    As an administrator
    I want to manage order cycles
}, js: true do
  include AuthenticationWorkflow
  include WebHelper

  scenario "listing order cycles" do
    # Given an order cycle
    oc = create(:order_cycle)

    # When I go to the admin order cycles page
    login_to_admin_section
    click_link 'Order Cycles'

    # Then I should see the basic fields
    page.should have_selector 'a', text: oc.name

    page.should have_selector "input[value='#{oc.orders_open_at}']"
    page.should have_selector "input[value='#{oc.orders_close_at}']"
    page.should have_content oc.coordinator.name

    # And I should see the suppliers and distributors
    oc.suppliers.each    { |s| page.should have_content s.name }
    oc.distributors.each { |d| page.should have_content d.name }

    # And I should see a thumbnail image for each product
    all('td.products img').count.should == 2
  end

  scenario "creating an order cycle" do
    # Given a coordinating enterprise
    create(:enterprise, name: 'My coordinator')

    # When I go to the new order cycle page
    login_to_admin_section
    click_link 'Order Cycles'
    click_link 'New Order Cycle'

    # And I fill in the basic fields and click Create
    fill_in 'order_cycle_name', with: 'Plums & Avos'
    fill_in 'order_cycle_orders_open_at', with: '2012-11-06 06:00:00'
    fill_in 'order_cycle_orders_close_at', with: '2012-11-13 17:00:00'
    select 'My coordinator', from: 'order_cycle_coordinator_id'
    click_button 'Create'

    # Then my order cycle should have been created
    page.should have_content 'Your order cycle has been created.'

    page.should have_selector 'a', text: 'Plums & Avos'

    page.should have_selector "input[value='2012-11-06 06:00:00 UTC']"
    page.should have_selector "input[value='2012-11-13 17:00:00 UTC']"
    page.should have_content 'My coordinator'
  end
end
