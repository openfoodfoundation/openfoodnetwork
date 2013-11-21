require 'spec_helper'

feature %q{
    As an administrator
    I want to manage order cycles
}, js: true do
  include AuthenticationWorkflow
  include WebHelper

  before :all do
    @orig_default_wait_time = Capybara.default_wait_time
    Capybara.default_wait_time = 5
  end

  after :all do
    Capybara.default_wait_time = @orig_default_wait_time
  end


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

    # And I should see the number of variants
    page.should have_selector 'td.products', text: '2 variants'
  end

  scenario "creating an order cycle", js: true do
    # Given coordinating, supplying and distributing enterprises with some products with variants
    coordinator = create(:distributor_enterprise, name: 'My coordinator')
    supplier = create(:supplier_enterprise, name: 'My supplier')
    product = create(:product, supplier: supplier)
    v1 = create(:variant, product: product)
    v2 = create(:variant, product: product)
    distributor = create(:distributor_enterprise, name: 'My distributor')

    # And some enterprise fees
    supplier_fee    = create(:enterprise_fee, enterprise: supplier,    name: 'Supplier fee')
    coordinator_fee = create(:enterprise_fee, enterprise: coordinator, name: 'Coord fee')
    distributor_fee = create(:enterprise_fee, enterprise: distributor, name: 'Distributor fee')

    # When I go to the new order cycle page
    login_to_admin_section
    click_link 'Order Cycles'
    click_link 'New Order Cycle'

    # And I fill in the basic fields
    fill_in 'order_cycle_name', with: 'Plums & Avos'
    fill_in 'order_cycle_orders_open_at', with: '2012-11-06 06:00:00'
    fill_in 'order_cycle_orders_close_at', with: '2012-11-13 17:00:00'
    select 'My coordinator', from: 'order_cycle_coordinator_id'

    # And I add a coordinator fee
    click_button 'Add coordinator fee'
    select 'Coord fee', from: 'order_cycle_coordinator_fee_0_id'

    # And I add a supplier and some products
    select 'My supplier', from: 'new_supplier_id'
    click_button 'Add supplier'
    page.find('table.exchanges tr.supplier td.products input').click
    check "order_cycle_incoming_exchange_0_variants_#{v1.id}"
    check "order_cycle_incoming_exchange_0_variants_#{v2.id}"

    # And I add a supplier fee
    within("tr.supplier-#{supplier.id}") { click_button 'Add fee' }
    select 'My supplier',  from: 'order_cycle_incoming_exchange_0_enterprise_fees_0_enterprise_id'
    select 'Supplier fee', from: 'order_cycle_incoming_exchange_0_enterprise_fees_0_enterprise_fee_id'

    # And I add a distributor with the same products
    select 'My distributor', from: 'new_distributor_id'
    click_button 'Add distributor'

    fill_in 'order_cycle_outgoing_exchange_0_pickup_time', with: 'pickup time'
    fill_in 'order_cycle_outgoing_exchange_0_pickup_instructions', with: 'pickup instructions'

    page.find('table.exchanges tr.distributor td.products input').click
    check "order_cycle_outgoing_exchange_0_variants_#{v1.id}"
    check "order_cycle_outgoing_exchange_0_variants_#{v2.id}"

    # And I add a distributor fee
    within("tr.distributor-#{distributor.id}") { click_button 'Add fee' }
    select 'My distributor',  from: 'order_cycle_outgoing_exchange_0_enterprise_fees_0_enterprise_id'
    select 'Distributor fee', from: 'order_cycle_outgoing_exchange_0_enterprise_fees_0_enterprise_fee_id'

    # And I click Create
    click_button 'Create'

    # Then my order cycle should have been created
    page.should have_content 'Your order cycle has been created.'

    page.should have_selector 'a', text: 'Plums & Avos'

    page.should have_selector "input[value='2012-11-06 06:00:00 +1100']"
    page.should have_selector "input[value='2012-11-13 17:00:00 +1100']"
    page.should have_content 'My coordinator'

    page.should have_selector 'td.suppliers', text: 'My supplier'
    page.should have_selector 'td.distributors', text: 'My distributor'

    # And it should have some fees
    OrderCycle.last.exchanges.first.enterprise_fees.should == [supplier_fee]
    OrderCycle.last.coordinator_fees.should                == [coordinator_fee]
    OrderCycle.last.exchanges.last.enterprise_fees.should  == [distributor_fee]

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
    wait_until { page.find('#order_cycle_name').value.present? }

    # Then I should see the basic settings
    page.find('#order_cycle_name').value.should == oc.name
    page.find('#order_cycle_orders_open_at').value.should == oc.orders_open_at.to_s
    page.find('#order_cycle_orders_close_at').value.should == oc.orders_close_at.to_s
    page.find('#order_cycle_coordinator_id').value.to_i.should == oc.coordinator_id
    page.should have_selector "select[name='order_cycle_coordinator_fee_0_id']"

    # And I should see the suppliers
    page.should have_selector 'td.supplier_name', :text => oc.suppliers.first.name
    page.should have_selector 'td.supplier_name', :text => oc.suppliers.last.name

    # And the suppliers should have products
    page.all('table.exchanges tbody tr.supplier').each do |row|
      row.find('td.products input').click

      products_row = page.all('table.exchanges tr.products').select { |r| r.visible? }.first
      products_row.should have_selector "input[type='checkbox'][checked='checked']"

      row.find('td.products input').click
    end

    # And the suppliers should have fees
    page.find('#order_cycle_incoming_exchange_0_enterprise_fees_0_enterprise_id option[selected=selected]').
      text.should == oc.suppliers.first.name
    page.find('#order_cycle_incoming_exchange_0_enterprise_fees_0_enterprise_fee_id option[selected=selected]').
      text.should == oc.suppliers.first.enterprise_fees.first.name

    page.find('#order_cycle_incoming_exchange_1_enterprise_fees_0_enterprise_id option[selected=selected]').
      text.should == oc.suppliers.last.name
    page.find('#order_cycle_incoming_exchange_1_enterprise_fees_0_enterprise_fee_id option[selected=selected]').
      text.should == oc.suppliers.last.enterprise_fees.first.name

    # And I should see the distributors
    page.should have_selector 'td.distributor_name', :text => oc.distributors.first.name
    page.should have_selector 'td.distributor_name', :text => oc.distributors.last.name

    page.find('#order_cycle_outgoing_exchange_0_pickup_time').value.should == 'time 0'
    page.find('#order_cycle_outgoing_exchange_0_pickup_instructions').value.should == 'instructions 0'
    page.find('#order_cycle_outgoing_exchange_1_pickup_time').value.should == 'time 1'
    page.find('#order_cycle_outgoing_exchange_1_pickup_instructions').value.should == 'instructions 1'

    # And the distributors should have products
    page.all('table.exchanges tbody tr.distributor').each do |row|
      row.find('td.products input').click

      products_row = page.all('table.exchanges tr.products').select { |r| r.visible? }.first
      products_row.should have_selector "input[type='checkbox'][checked='checked']"

      row.find('td.products input').click
    end

    # And the distributors should have fees
    page.find('#order_cycle_outgoing_exchange_0_enterprise_fees_0_enterprise_id option[selected=selected]').
      text.should == oc.distributors.first.name
    page.find('#order_cycle_outgoing_exchange_0_enterprise_fees_0_enterprise_fee_id option[selected=selected]').
      text.should == oc.distributors.first.enterprise_fees.first.name

    page.find('#order_cycle_outgoing_exchange_1_enterprise_fees_0_enterprise_id option[selected=selected]').
      text.should == oc.distributors.last.name
    page.find('#order_cycle_outgoing_exchange_1_enterprise_fees_0_enterprise_fee_id option[selected=selected]').
      text.should == oc.distributors.last.enterprise_fees.first.name
  end


  scenario "updating an order cycle", js: true do
    # Given an order cycle with all the settings
    oc = create(:order_cycle)
    initial_variants = oc.variants

    # And a coordinating, supplying and distributing enterprise with some products with variants
    coordinator = create(:distributor_enterprise, name: 'My coordinator')
    supplier = create(:supplier_enterprise, name: 'My supplier')
    distributor = create(:distributor_enterprise, name: 'My distributor')
    product = create(:product, supplier: supplier)
    v1 = create(:variant, product: product)
    v2 = create(:variant, product: product)

    # And some enterprise fees
    supplier_fee1 = create(:enterprise_fee, enterprise: supplier, name: 'Supplier fee 1')
    supplier_fee2 = create(:enterprise_fee, enterprise: supplier, name: 'Supplier fee 2')
    coordinator_fee1 = create(:enterprise_fee, enterprise: coordinator, name: 'Coord fee 1')
    coordinator_fee2 = create(:enterprise_fee, enterprise: coordinator, name: 'Coord fee 2')
    distributor_fee1 = create(:enterprise_fee, enterprise: distributor, name: 'Distributor fee 1')
    distributor_fee2 = create(:enterprise_fee, enterprise: distributor, name: 'Distributor fee 2')

    # When I go to its edit page
    login_to_admin_section
    click_link 'Order Cycles'
    click_link oc.name
    wait_until { page.find('#order_cycle_name').value.present? }

    # And I update it
    fill_in 'order_cycle_name', with: 'Plums & Avos'
    fill_in 'order_cycle_orders_open_at', with: '2012-11-06 06:00:00'
    fill_in 'order_cycle_orders_close_at', with: '2012-11-13 17:00:00'
    select 'My coordinator', from: 'order_cycle_coordinator_id'

    # And I configure some coordinator fees
    click_button 'Add coordinator fee'
    select 'Coord fee 1', from: 'order_cycle_coordinator_fee_0_id'
    click_button 'Add coordinator fee'
    click_button 'Add coordinator fee'
    click_link 'order_cycle_coordinator_fee_2_remove'
    select 'Coord fee 2', from: 'order_cycle_coordinator_fee_1_id'

    # And I add a supplier and some products
    select 'My supplier', from: 'new_supplier_id'
    click_button 'Add supplier'
    page.all("table.exchanges tr.supplier td.products input").each { |e| e.click }

    uncheck "order_cycle_incoming_exchange_1_variants_#{initial_variants.last.id}"
    check "order_cycle_incoming_exchange_2_variants_#{v1.id}"
    check "order_cycle_incoming_exchange_2_variants_#{v2.id}"

    # And I configure some supplier fees
    within("tr.supplier-#{supplier.id}") { click_button 'Add fee' }
    select 'My supplier', from: 'order_cycle_incoming_exchange_2_enterprise_fees_0_enterprise_id'
    select 'Supplier fee 1', from: 'order_cycle_incoming_exchange_2_enterprise_fees_0_enterprise_fee_id'
    within("tr.supplier-#{supplier.id}") { click_button 'Add fee' }
    within("tr.supplier-#{supplier.id}") { click_button 'Add fee' }
    click_link 'order_cycle_incoming_exchange_2_enterprise_fees_0_remove'
    select 'My supplier', from: 'order_cycle_incoming_exchange_2_enterprise_fees_0_enterprise_id'
    select 'Supplier fee 2', from: 'order_cycle_incoming_exchange_2_enterprise_fees_0_enterprise_fee_id'

    # And I add a distributor and some products
    select 'My distributor', from: 'new_distributor_id'
    click_button 'Add distributor'

    fill_in 'order_cycle_outgoing_exchange_0_pickup_time', with: 'New time 0'
    fill_in 'order_cycle_outgoing_exchange_0_pickup_instructions', with: 'New instructions 0'
    fill_in 'order_cycle_outgoing_exchange_1_pickup_time', with: 'New time 1'
    fill_in 'order_cycle_outgoing_exchange_1_pickup_instructions', with: 'New instructions 1'

    page.all("table.exchanges tr.distributor td.products input").each { |e| e.click }

    uncheck "order_cycle_outgoing_exchange_2_variants_#{v1.id}"
    check "order_cycle_outgoing_exchange_2_variants_#{v2.id}"

    # And I configure some distributor fees
    within("tr.distributor-#{distributor.id}") { click_button 'Add fee' }
    select 'My distributor', from: 'order_cycle_outgoing_exchange_2_enterprise_fees_0_enterprise_id'
    select 'Distributor fee 1', from: 'order_cycle_outgoing_exchange_2_enterprise_fees_0_enterprise_fee_id'
    within("tr.distributor-#{distributor.id}") { click_button 'Add fee' }
    within("tr.distributor-#{distributor.id}") { click_button 'Add fee' }
    click_link 'order_cycle_outgoing_exchange_2_enterprise_fees_0_remove'
    select 'My distributor', from: 'order_cycle_outgoing_exchange_2_enterprise_fees_0_enterprise_id'
    select 'Distributor fee 2', from: 'order_cycle_outgoing_exchange_2_enterprise_fees_0_enterprise_fee_id'

    # And I click Update
    click_button 'Update'

    # Then my order cycle should have been updated
    page.should have_content 'Your order cycle has been updated.'

    page.should have_selector 'a', text: 'Plums & Avos'

    page.should have_selector "input[value='2012-11-06 06:00:00 +1100']"
    page.should have_selector "input[value='2012-11-13 17:00:00 +1100']"
    page.should have_content 'My coordinator'

    page.should have_selector 'td.suppliers', text: 'My supplier'
    page.should have_selector 'td.distributors', text: 'My distributor'

    # And my coordinator fees should have been configured
    OrderCycle.last.coordinator_fee_ids.sort.should == [coordinator_fee1.id, coordinator_fee2.id].sort

    # And my supplier fees should have been configured
    OrderCycle.last.exchanges.incoming.last.enterprise_fee_ids.should == [supplier_fee2.id]

    # And my distributor fees should have been configured
    OrderCycle.last.exchanges.outgoing.last.enterprise_fee_ids.should == [distributor_fee2.id]

    # And it should have some variants selected
    selected_initial_variants = initial_variants.take initial_variants.size - 1
    OrderCycle.last.variants.map(&:id).sort.should == (selected_initial_variants.map(&:id) + [v1.id, v2.id]).sort

    # And the collection details should have been updated
    OrderCycle.last.exchanges.where(pickup_time: 'New time 0', pickup_instructions: 'New instructions 0').should be_present
    OrderCycle.last.exchanges.where(pickup_time: 'New time 1', pickup_instructions: 'New instructions 1').should be_present
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

  scenario "cloning an order cycle" do
    # Given an order cycle
    oc = create(:order_cycle)

    # When I clone it
    login_to_admin_section
    click_link 'Order Cycles'
    first('a.clone-order-cycle').click
    flash_message.should == "Your order cycle #{oc.name} has been cloned."

    # Then I should have clone of the order cycle
    occ = OrderCycle.last
    occ.name.should == "COPY OF #{oc.name}"
  end


  context 'as an Enterprise user' do

    let(:supplier1) { create(:supplier_enterprise, name: 'First Supplier') }
    let(:supplier2) { create(:supplier_enterprise, name: 'Another Supplier') }
    let(:distributor1) { create(:distributor_enterprise, name: 'First Distributor') }
    let(:distributor2) { create(:distributor_enterprise, name: 'Another Distributor') }
    let!(:distributor1_fee) { create(:enterprise_fee, enterprise: distributor1, name: 'First Distributor Fee') }
    before(:each) do
      product = create(:product, supplier: supplier1)
      product.distributors << distributor1
      product.save!

      @new_user = create_enterprise_user
      @new_user.enterprise_roles.build(enterprise: supplier1).save
      @new_user.enterprise_roles.build(enterprise: distributor1).save

      login_to_admin_as @new_user
    end

    scenario "can view products I am coordinating" do
      oc_user_coordinating = create(:simple_order_cycle, { coordinator: supplier1, name: 'Order Cycle 1' } )
      oc_for_other_user = create(:simple_order_cycle, { coordinator: supplier2, name: 'Order Cycle 2' } )

      click_link "Order Cycles"

      page.should have_content oc_user_coordinating.name
      page.should_not have_content oc_for_other_user.name
    end

    scenario "can create a new order cycle" do
      click_link "Order Cycles"
      click_link 'New Order Cycle'

      fill_in 'order_cycle_name', with: 'My order cycle'
      fill_in 'order_cycle_orders_open_at', with: '2012-11-06 06:00:00'
      fill_in 'order_cycle_orders_close_at', with: '2012-11-13 17:00:00'

      select 'First Supplier', from: 'new_supplier_id'
      click_button 'Add supplier'

      select 'First Distributor', from: 'order_cycle_coordinator_id'
      click_button 'Add coordinator fee'
      select 'First Distributor Fee', from: 'order_cycle_coordinator_fee_0_id'

      select 'First Distributor', from: 'new_distributor_id'
      click_button 'Add distributor'

      # Should only have suppliers / distributors listed which the user can manage
      within "#new_supplier_id" do
        page.should_not have_content supplier2.name
      end
      within "#new_distributor_id" do
        page.should_not have_content distributor2.name
      end
      within "#order_cycle_coordinator_id" do
        page.should_not have_content distributor2.name
        page.should_not have_content supplier1.name
        page.should_not have_content supplier2.name
      end

      click_button 'Create'

      flash_message.should == "Your order cycle has been created."
      order_cycle = OrderCycle.find_by_name('My order cycle')
      order_cycle.coordinator.should == distributor1
    end

    scenario "cloning an order cycle" do
      oc = create(:simple_order_cycle)

      click_link "Order Cycles"
      first('a.clone-order-cycle').click
      flash_message.should == "Your order cycle #{oc.name} has been cloned."

      # Then I should have clone of the order cycle
      occ = OrderCycle.last
      occ.name.should == "COPY OF #{oc.name}"
    end

  end

end
