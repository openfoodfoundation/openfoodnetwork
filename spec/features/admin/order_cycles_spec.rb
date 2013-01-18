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
    # Given coordinating, supplying and distributing enterprises with some products with variants
    create(:enterprise, name: 'My coordinator')
    supplier = create(:supplier_enterprise, name: 'My supplier')
    product = create(:product, supplier: supplier)
    create(:variant, product: product)
    create(:variant, product: product)
    distributor = create(:distributor_enterprise, name: 'My distributor')

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
    page.find('table.exchanges tr.supplier td.products input').click
    check 'order_cycle_incoming_exchange_0_variants_2'
    check 'order_cycle_incoming_exchange_0_variants_3'

    # And I add a distributor with the same products
    select 'My distributor', from: 'new_distributor_id'
    click_button 'Add distributor'

    fill_in 'order_cycle_outgoing_exchange_0_pickup_time', with: 'pickup time'
    fill_in 'order_cycle_outgoing_exchange_0_pickup_instructions', with: 'pickup instructions'

    page.find('table.exchanges tr.distributor td.products input').click
    check 'order_cycle_outgoing_exchange_0_variants_2'
    check 'order_cycle_outgoing_exchange_0_variants_3'

    # And I click Create
    click_button 'Create'

    # Then my order cycle should have been created
    page.should have_content 'Your order cycle has been created.'

    page.should have_selector 'a', text: 'Plums & Avos'

    page.should have_selector "input[value='2012-11-06 06:00:00 UTC']"
    page.should have_selector "input[value='2012-11-13 17:00:00 UTC']"
    page.should have_content 'My coordinator'

    page.should have_selector 'td.suppliers', text: 'My supplier'
    page.should have_selector 'td.distributors', text: 'My distributor'

    # And it should have some variants selected
    OrderCycle.last.exchanges.first.variants.count.should == 2
    OrderCycle.last.exchanges.last.variants.count.should == 2

    # And my pickup time and instructions should have been saved
    oc = OrderCycle.last
    exchange = oc.exchanges.where(:sender_id => oc.coordinator_id).first
    exchange.pickup_time.should == 'pickup time'
    exchange.pickup_instructions.should == 'pickup instructions'
  end


  scenario "editing an order cycle" do
    # Given an order cycle with all the settings
    oc = create(:order_cycle)

    # When I edit it
    login_to_admin_section
    click_link 'Order Cycles'
    click_link oc.name

    # Then I should see the basic settings
    sleep(1)
    page.find('#order_cycle_name').value.should == oc.name
    page.find('#order_cycle_orders_open_at').value.should == oc.orders_open_at.to_s
    page.find('#order_cycle_orders_close_at').value.should == oc.orders_close_at.to_s
    page.find('#order_cycle_coordinator_id').value.to_i.should == oc.coordinator_id

    # And I should see the suppliers with products
    page.should have_selector 'td.supplier_name', :text => oc.suppliers.first.name
    page.should have_selector 'td.supplier_name', :text => oc.suppliers.last.name

    page.all('table.exchanges tbody tr.supplier').each do |row|
      row.find('td.products input').click

      products_row = page.all('table.exchanges tr.products').select { |r| r.visible? }.first
      products_row.should have_selector "input[type='checkbox'][checked='checked']"

      row.find('td.products input').click
    end

    # And I should see the distributors with products
    page.should have_selector 'td.distributor_name', :text => oc.distributors.first.name
    page.should have_selector 'td.distributor_name', :text => oc.distributors.last.name

    page.all('table.exchanges tbody tr.distributor').each do |row|
      row.find('td.products input').click

      products_row = page.all('table.exchanges tr.products').select { |r| r.visible? }.first
      products_row.should have_selector "input[type='checkbox'][checked='checked']"

      row.find('td.products input').click
    end
  end


  scenario "updating an order cycle" do
    # Given an order cycle with all the settings
    oc = create(:order_cycle)

    # And a coordinating, supplying and distributing enterprise with some products with variants
    create(:enterprise, name: 'My coordinator')
    supplier = create(:supplier_enterprise, name: 'My supplier')
    distributor = create(:distributor_enterprise, name: 'My distributor')
    product = create(:product, supplier: supplier)
    v1 = create(:variant, product: product)
    v2 = create(:variant, product: product)

    # When I go to its edit page
    login_to_admin_section
    click_link 'Order Cycles'
    click_link oc.name
    sleep 1

    # And I update it
    fill_in 'order_cycle_name', with: 'Plums & Avos'
    fill_in 'order_cycle_orders_open_at', with: '2012-11-06 06:00:00'
    fill_in 'order_cycle_orders_close_at', with: '2012-11-13 17:00:00'
    select 'My coordinator', from: 'order_cycle_coordinator_id'

    # And I add a supplier and some products
    select 'My supplier', from: 'new_supplier_id'
    click_button 'Add supplier'
    page.all("table.exchanges tr.supplier td.products input").each { |e| e.click }

    uncheck "order_cycle_incoming_exchange_1_variants_2"
    check "order_cycle_incoming_exchange_2_variants_#{v1.id}"
    check "order_cycle_incoming_exchange_2_variants_#{v2.id}"

    # And I add a distributor and some products
    select 'My distributor', from: 'new_distributor_id'
    click_button 'Add distributor'
    page.all("table.exchanges tr.distributor td.products input").each { |e| e.click }

    uncheck "order_cycle_outgoing_exchange_2_variants_#{v1.id}"
    check "order_cycle_outgoing_exchange_2_variants_#{v2.id}"

    # And I click Update
    click_button 'Update'

    # Then my order cycle should have been updated
    page.should have_content 'Your order cycle has been updated.'

    page.should have_selector 'a', text: 'Plums & Avos'

    page.should have_selector "input[value='2012-11-06 06:00:00 UTC']"
    page.should have_selector "input[value='2012-11-13 17:00:00 UTC']"
    page.should have_content 'My coordinator'

    page.should have_selector 'td.suppliers', text: 'My supplier'
    page.should have_selector 'td.distributors', text: 'My distributor'

    # And it should have some variants selected
    OrderCycle.last.variants.map { |v| v.id }.sort.should == [1, v1.id, v2.id].sort
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
