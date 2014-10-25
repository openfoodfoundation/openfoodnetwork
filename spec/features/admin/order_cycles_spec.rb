require 'spec_helper'

feature %q{
    As an administrator
    I want to manage order cycles
}, js: true do
  include AuthenticationWorkflow
  include WebHelper

  scenario "listing order cycles" do
    # Given some order cycles (created in an arbitrary order)
    oc4 = create(:simple_order_cycle, name: '4',
                 orders_open_at: 2.day.from_now, orders_close_at: 1.month.from_now)
    oc2 = create(:simple_order_cycle, name: '2', orders_close_at: 1.month.from_now)
    oc6 = create(:simple_order_cycle, name: '6',
                 orders_open_at: 1.month.ago, orders_close_at: 3.weeks.ago)
    oc3 = create(:simple_order_cycle, name: '3',
                 orders_open_at: 1.day.from_now, orders_close_at: 1.month.from_now)
    oc5 = create(:simple_order_cycle, name: '5',
                 orders_open_at: 1.month.ago, orders_close_at: 2.weeks.ago)
    oc1 = create(:order_cycle, name: '1')
    oc0 = create(:simple_order_cycle, name: '0',
                 orders_open_at: nil, orders_close_at: nil)

    # When I go to the admin order cycles page
    login_to_admin_section
    click_link 'Order Cycles'

    # Then the order cycles should be ordered correctly
    page.all('#listing_order_cycles tr td:first-child').map(&:text).should ==
      ['0', '1', '2', '3', '4', '5', '6']

    # And the rows should have the correct classes
    page.should have_selector "#listing_order_cycles tr.order-cycle-#{oc0.id}.undated"
    page.should have_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}.open"
    page.should have_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}.open"
    page.should have_selector "#listing_order_cycles tr.order-cycle-#{oc3.id}.upcoming"
    page.should have_selector "#listing_order_cycles tr.order-cycle-#{oc4.id}.upcoming"
    page.should have_selector "#listing_order_cycles tr.order-cycle-#{oc5.id}.closed"
    page.should have_selector "#listing_order_cycles tr.order-cycle-#{oc6.id}.closed"

    # And I should see all the details for an order cycle
    # (the table includes a hidden field between each row, making this nth-child(3) instead of 2)
    within('table#listing_order_cycles tbody tr:nth-child(3)') do
      # Then I should see the basic fields
      page.should have_selector 'a', text: oc1.name

      page.should have_selector "input[value='#{oc1.orders_open_at}']"
      page.should have_selector "input[value='#{oc1.orders_close_at}']"
      page.should have_content oc1.coordinator.name

      # And I should see the suppliers and distributors
      oc1.suppliers.each    { |s| page.should have_content s.name }
      oc1.distributors.each { |d| page.should have_content d.name }

      # And I should see the number of variants
      page.should have_selector 'td.products', text: '2 variants'
    end
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
    OrderCycle.last.exchanges.incoming.first.enterprise_fees.should == [supplier_fee]
    OrderCycle.last.coordinator_fees.should                         == [coordinator_fee]
    OrderCycle.last.exchanges.outgoing.first.enterprise_fees.should == [distributor_fee]

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
    supplier = oc.suppliers.sort_by(&:name).first
    page.should have_select 'order_cycle_incoming_exchange_0_enterprise_fees_0_enterprise_id', selected: supplier.name
    page.should have_select 'order_cycle_incoming_exchange_0_enterprise_fees_0_enterprise_fee_id', selected: supplier.enterprise_fees.first.name

    supplier = oc.suppliers.sort_by(&:name).last
    page.should have_select 'order_cycle_incoming_exchange_1_enterprise_fees_0_enterprise_id', selected: supplier.name
    page.should have_select 'order_cycle_incoming_exchange_1_enterprise_fees_0_enterprise_fee_id', selected: supplier.enterprise_fees.first.name

    # And I should see the distributors
    page.should have_selector 'td.distributor_name', :text => oc.distributors.first.name
    page.should have_selector 'td.distributor_name', :text => oc.distributors.last.name

    page.should have_field 'order_cycle_outgoing_exchange_0_pickup_time', with: 'time 0'
    page.should have_field 'order_cycle_outgoing_exchange_0_pickup_instructions', with: 'instructions 0'
    page.should have_field 'order_cycle_outgoing_exchange_1_pickup_time', with: 'time 1'
    page.should have_field 'order_cycle_outgoing_exchange_1_pickup_instructions', with: 'instructions 1'

    # And the distributors should have products
    page.all('table.exchanges tbody tr.distributor').each do |row|
      row.find('td.products input').click

      products_row = page.all('table.exchanges tr.products').select { |r| r.visible? }.first
      products_row.should have_selector "input[type='checkbox'][checked='checked']"

      row.find('td.products input').click
    end

    # And the distributors should have fees
    distributor = oc.distributors.sort_by(&:id).first
    page.should have_select 'order_cycle_outgoing_exchange_0_enterprise_fees_0_enterprise_id', selected: distributor.name
    page.should have_select 'order_cycle_outgoing_exchange_0_enterprise_fees_0_enterprise_fee_id', selected: distributor.enterprise_fees.first.name

    distributor = oc.distributors.sort_by(&:id).last
    page.should have_select 'order_cycle_outgoing_exchange_1_enterprise_fees_0_enterprise_id', selected: distributor.name
    page.should have_select 'order_cycle_outgoing_exchange_1_enterprise_fees_0_enterprise_fee_id', selected: distributor.enterprise_fees.first.name
  end


  scenario "editing an order cycle with an exchange between the same enterprise" do
    c = create(:distributor_enterprise, is_primary_producer: true)
    login_to_admin_section

    # Given two order cycles, one with a mono-enterprise incoming exchange...
    oc_incoming = create(:simple_order_cycle, suppliers: [c], coordinator: c)

    # And the other with a mono-enterprise outgoing exchange
    oc_outgoing = create(:simple_order_cycle, coordinator: c, distributors: [c])

    # When I edit the first order cycle, the exchange should appear as incoming
    visit edit_admin_order_cycle_path(oc_incoming)
    page.should     have_selector 'table.exchanges tr.supplier'
    page.should_not have_selector 'table.exchanges tr.distributor'

    # And when I edit the second order cycle, the exchange should appear as outgoing
    visit edit_admin_order_cycle_path(oc_outgoing)
    page.should     have_selector 'table.exchanges tr.distributor'
    page.should_not have_selector 'table.exchanges tr.supplier'
  end


  scenario "updating an order cycle", js: true do
    # Given an order cycle with all the settings
    oc = create(:order_cycle)
    initial_variants = oc.variants.sort_by &:id

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

    page.should have_selector "#order_cycle_incoming_exchange_1_variants_#{initial_variants.last.id}", visible: true
    page.find("#order_cycle_incoming_exchange_1_variants_#{initial_variants.last.id}", visible: true).click # uncheck (with visible:true filter)
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
    oc1 = create(:order_cycle)
    oc2 = create(:order_cycle)
    oc3 = create(:order_cycle)

    # When I go to the order cycles page
    login_to_admin_section
    click_link 'Order Cycles'

    # And I fill in some new opening/closing times and save them
    within("tr.order-cycle-#{oc1.id}") do
      all('input').first.set '2012-12-01 12:00:00'
      all('input').last.set '2012-12-01 12:00:01'
    end

    within("tr.order-cycle-#{oc2.id}") do
      all('input').first.set '2012-12-01 12:00:02'
      all('input').last.set '2012-12-01 12:00:03'
    end

    within("tr.order-cycle-#{oc3.id}") do
      all('input').first.set '2012-12-01 12:00:04'
      all('input').last.set '2012-12-01 12:00:05'
    end

    click_button 'Update'

    # Then my times should have been saved
    flash_message.should == 'Order cycles have been updated.'
    OrderCycle.order('id ASC').map { |oc| oc.orders_open_at.sec }.should == [0, 2, 4]
    OrderCycle.order('id ASC').map { |oc| oc.orders_close_at.sec }.should == [1, 3, 5]
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


  scenario "removing a master variant from an order cycle when further variants have been added" do
    # Given a product with a variant, with its master variant included in the order cycle
    # (this usually happens when a product is added to an order cycle, then variants are added
    #  to the product after the fact)
    s = create(:supplier_enterprise)
    p = create(:simple_product, supplier: s)
    v = create(:variant, product: p)
    d = create(:distributor_enterprise)
    oc = create(:simple_order_cycle, suppliers: [s], distributors: [d], variants: [p.master])
    exchange_ids = oc.exchanges.pluck :id
    ExchangeVariant.where(exchange_id: exchange_ids, variant_id: p.master.id).should_not be_empty

    # When I go to the order cycle page and remove the obsolete master
    login_to_admin_section
    click_link 'Order Cycles'
    click_link oc.name
    within("table.exchanges tbody tr.supplier") { page.find('td.products input').click }
    page.find("#order_cycle_incoming_exchange_0_variants_#{p.master.id}", visible: true).click # uncheck
    click_button "Update"

    # Then the master variant should have been removed from all exchanges
    page.should have_content "Your order cycle has been updated."
    ExchangeVariant.where(exchange_id: exchange_ids, variant_id: p.master.id).should be_empty
  end


  context "as an enterprise user" do

    let!(:supplier_managed) { create(:supplier_enterprise, name: 'Managed supplier') }
    let!(:supplier_unmanaged) { create(:supplier_enterprise, name: 'Unmanaged supplier') }
    let!(:supplier_permitted) { create(:supplier_enterprise, name: 'Permitted supplier') }
    let!(:distributor_managed) { create(:distributor_enterprise, name: 'Managed distributor') }
    let!(:distributor_unmanaged) { create(:distributor_enterprise, name: 'Unmanaged Distributor') }
    let!(:distributor_permitted) { create(:distributor_enterprise, name: 'Permitted distributor') }
    let!(:distributor_managed_fee) { create(:enterprise_fee, enterprise: distributor_managed, name: 'Managed distributor fee') }
    let!(:supplier_permitted_relationship) do
      create(:enterprise_relationship, parent: supplier_permitted, child: supplier_managed,
             permissions_list: [:add_to_order_cycle])
    end
    let!(:distributor_permitted_relationship) do
      create(:enterprise_relationship, parent: distributor_permitted, child: distributor_managed,
             permissions_list: [:add_to_order_cycle])
    end
    let!(:product_managed) { create(:product, supplier: supplier_managed) }
    let!(:product_permitted) { create(:product, supplier: supplier_permitted) }

    before do
      @new_user = create_enterprise_user
      @new_user.enterprise_roles.build(enterprise: supplier_managed).save
      @new_user.enterprise_roles.build(enterprise: distributor_managed).save

      login_to_admin_as @new_user
    end

    scenario "viewing a list of order cycles I am coordinating" do
      oc_user_coordinating = create(:simple_order_cycle, { suppliers: [supplier_managed, supplier_unmanaged], coordinator: supplier_managed, distributors: [distributor_managed, distributor_unmanaged], name: 'Order Cycle 1' } )
      oc_for_other_user = create(:simple_order_cycle, { coordinator: supplier_unmanaged, name: 'Order Cycle 2' } )

      click_link "Order Cycles"

      # I should see only the order cycle I am coordinating
      page.should have_content oc_user_coordinating.name
      page.should_not have_content oc_for_other_user.name
      
      # The order cycle should show enterprises that I manage
      page.should have_selector 'td.suppliers',    text: supplier_managed.name
      page.should have_selector 'td.distributors', text: distributor_managed.name

      # The order cycle should not show enterprises that I don't manage
      page.should_not have_selector 'td.suppliers',    text: supplier_unmanaged.name
      page.should_not have_selector 'td.distributors', text: distributor_unmanaged.name
    end

    scenario "creating a new order cycle" do
      click_link "Order Cycles"
      click_link 'New Order Cycle'

      fill_in 'order_cycle_name', with: 'My order cycle'
      fill_in 'order_cycle_orders_open_at', with: '2012-11-06 06:00:00'
      fill_in 'order_cycle_orders_close_at', with: '2012-11-13 17:00:00'

      select 'Managed supplier', from: 'new_supplier_id'
      click_button 'Add supplier'
      select 'Permitted supplier', from: 'new_supplier_id'
      click_button 'Add supplier'

      select_incoming_variant supplier_managed, 0, product_managed.master
      select_incoming_variant supplier_permitted, 1, product_permitted.master

      select 'Managed distributor', from: 'order_cycle_coordinator_id'
      click_button 'Add coordinator fee'
      select 'Managed distributor fee', from: 'order_cycle_coordinator_fee_0_id'

      select 'Managed distributor', from: 'new_distributor_id'
      click_button 'Add distributor'
      select 'Permitted distributor', from: 'new_distributor_id'
      click_button 'Add distributor'

      # Should only have suppliers / distributors listed which the user is managing or
      # has E2E permission to add products to order cycles
      page.should_not have_select 'new_supplier_id', with_options: [supplier_unmanaged.name]
      page.should_not have_select 'new_distributor_id', with_options: [distributor_unmanaged.name]

      [distributor_unmanaged.name, supplier_managed.name, supplier_unmanaged.name].each do |enterprise_name|
        page.should_not have_select 'order_cycle_coordinator_id', with_options: [enterprise_name]
      end

      click_button 'Create'

      flash_message.should == "Your order cycle has been created."
      order_cycle = OrderCycle.find_by_name('My order cycle')
      order_cycle.suppliers.sort.should == [supplier_managed, supplier_permitted].sort
      order_cycle.coordinator.should == distributor_managed
      order_cycle.distributors.sort.should == [distributor_managed, distributor_permitted].sort
    end

    scenario "editing an order cycle does not affect exchanges we don't manage" do
      oc = create(:simple_order_cycle, { suppliers: [supplier_managed, supplier_permitted, supplier_unmanaged], coordinator: supplier_managed, distributors: [distributor_managed, distributor_permitted, distributor_unmanaged], name: 'Order Cycle 1' } )

      visit edit_admin_order_cycle_path(oc)

      # I should not see exchanges for supplier_unmanaged or distributor_unmanaged
      page.all('tr.supplier').count.should == 2
      page.all('tr.distributor').count.should == 2

      # When I save, then those exchanges should remain
      click_button 'Update'
      page.should have_content "Your order cycle has been updated."

      oc.reload
      oc.suppliers.sort.should == [supplier_managed, supplier_permitted, supplier_unmanaged].sort
      oc.coordinator.should == supplier_managed
      oc.distributors.sort.should == [distributor_managed, distributor_permitted, distributor_unmanaged].sort
    end

    scenario "editing an order cycle" do
      oc = create(:simple_order_cycle, { suppliers: [supplier_managed, supplier_permitted, supplier_unmanaged], coordinator: supplier_managed, distributors: [distributor_managed, distributor_permitted, distributor_unmanaged], name: 'Order Cycle 1' } )

      visit edit_admin_order_cycle_path(oc)

      # When I remove all the exchanges and save
      page.find("tr.supplier-#{supplier_managed.id} a.remove-exchange").click
      page.find("tr.supplier-#{supplier_permitted.id} a.remove-exchange").click
      page.find("tr.distributor-#{distributor_managed.id} a.remove-exchange").click
      page.find("tr.distributor-#{distributor_permitted.id} a.remove-exchange").click
      click_button 'Update'

      # Then the exchanges should be removed
      page.should have_content "Your order cycle has been updated."

      oc.reload
      oc.suppliers.should == [supplier_unmanaged]
      oc.coordinator.should == supplier_managed
      oc.distributors.should == [distributor_unmanaged]
    end


    scenario "cloning an order cycle" do
      oc = create(:simple_order_cycle, coordinator: distributor_managed)

      click_link "Order Cycles"
      first('a.clone-order-cycle').click
      flash_message.should == "Your order cycle #{oc.name} has been cloned."

      # Then I should have clone of the order cycle
      occ = OrderCycle.last
      occ.name.should == "COPY OF #{oc.name}"
    end

  end


  private

  def select_incoming_variant(supplier, exchange_no, variant)
    page.find("table.exchanges tr.supplier-#{supplier.id} td.products input").click
    check "order_cycle_incoming_exchange_#{exchange_no}_variants_#{variant.id}"
  end
end
