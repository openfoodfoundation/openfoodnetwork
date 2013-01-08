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
    # Given a coordinating enterprise and a supplying enterprise with some products with variants
    create(:enterprise, name: 'My coordinator')
    supplier = create(:supplier_enterprise, name: 'My supplier')
    product = create(:product, supplier: supplier)
    create(:variant, product: product)
    create(:variant, product: product)

    # When I go to the new order cycle page
    login_to_admin_section
    click_link 'Order Cycles'
    click_link 'New Order Cycle'

    # And I fill in the basic fields
    fill_in 'order_cycle_name', with: 'Plums & Avos'
    fill_in 'order_cycle_orders_open_at', with: '2012-11-06 06:00:00'
    fill_in 'order_cycle_orders_close_at', with: '2012-11-13 17:00:00'
    select 'My coordinator', from: 'order_cycle_coordinator_id'

    # And I add a supplier and some products
    select 'My supplier', from: 'new_supplier_id'
    click_button 'Add supplier'
    click_button 'Products'
    check 'order_cycle_exchange_0_exchange_variants_1'
    check 'order_cycle_exchange_0_exchange_variants_3'

    # And I click Create
    click_button 'Create'

    # Then my order cycle should have been created
    page.should have_content 'Your order cycle has been created.'

    page.should have_selector 'a', text: 'Plums & Avos'

    page.should have_selector "input[value='2012-11-06 06:00:00 UTC']"
    page.should have_selector "input[value='2012-11-13 17:00:00 UTC']"
    page.should have_content 'My coordinator'

    page.should have_selector 'td.suppliers', text: 'My supplier'

    # And it should have some variants selected
    OrderCycle.last.exchanges.first.variants.count.should == 2
  end

  scenario "updating many order cycle opening/closing times at once" do
    # Given three order cycles
    3.times { create(:order_cycle) }

    # When I go to the order cycles page
    login_to_admin_section
    click_link 'Order Cycles'

    # And I fill in some new opening/closing times and save them
    fill_in 'order_cycle_set_collection_attributes_0_orders_open_at', :with => '2012-12-01 12:00:00'
    fill_in 'order_cycle_set_collection_attributes_0_orders_close_at', :with => '2012-12-01 12:00:01'
    fill_in 'order_cycle_set_collection_attributes_1_orders_open_at', :with => '2012-12-01 12:00:02'
    fill_in 'order_cycle_set_collection_attributes_1_orders_close_at', :with => '2012-12-01 12:00:03'
    fill_in 'order_cycle_set_collection_attributes_2_orders_open_at', :with => '2012-12-01 12:00:04'
    fill_in 'order_cycle_set_collection_attributes_2_orders_close_at', :with => '2012-12-01 12:00:05'
    click_button 'Update'

    # Then my times should have been saved
    flash_message.should == 'Order cycles have been updated.'
    OrderCycle.all.map { |oc| oc.orders_open_at.sec }.should == [0, 2, 4]
    OrderCycle.all.map { |oc| oc.orders_close_at.sec }.should == [1, 3, 5]
  end

end
