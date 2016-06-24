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
    oc7 = create(:simple_order_cycle, name: '0',
                orders_open_at: 2.months.ago, orders_close_at: 5.weeks.ago)

    # When I go to the admin order cycles page
    login_to_admin_section
    click_link 'Order Cycles'

    # Then the order cycles should be ordered correctly
    expect(page).to have_selector "#listing_order_cycles tr td:first-child", count: 7
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
    within('table#listing_order_cycles tbody tr:nth-child(2)') do
      # Then I should see the basic fields
      page.should have_selector 'a', text: oc1.name

      page.should have_input "oc#{oc1.id}[orders_open_at]", value: oc1.orders_open_at
      page.should have_input "oc#{oc1.id}[orders_close_at]", value: oc1.orders_close_at
      page.should have_content oc1.coordinator.name

      # And I should see the suppliers and distributors
      oc1.suppliers.each    { |s| page.should have_content s.name }
      oc1.distributors.each { |d| page.should have_content d.name }

      # And I should see the number of variants
      page.should have_selector 'td.products', text: '2 variants'
    end

    # I can load more order_cycles
    page.should have_no_selector "#listing_order_cycles tr.order-cycle-#{oc7.id}"
    click_button "Show 30 more days"
    page.should have_selector "#listing_order_cycles tr.order-cycle-#{oc7.id}"
  end

  context "with specific time" do
    let(:order_cycle_opening_time) { Time.zone.local(2040, 11, 06, 06, 00, 00).strftime("%F %T %z") }
    let(:order_cycle_closing_time) { Time.zone.local(2040, 11, 13, 17, 00, 00).strftime("%F %T %z") }

    scenario "creating an order cycle", js: true do
      page.driver.resize(1280, 2000)

      # Given coordinating, supplying and distributing enterprises with some products with variants
      coordinator = create(:distributor_enterprise, name: 'My coordinator')
      supplier = create(:supplier_enterprise, name: 'My supplier')
      product = create(:product, supplier: supplier)
      v1 = create(:variant, product: product)
      v2 = create(:variant, product: product)
      distributor = create(:distributor_enterprise, name: 'My distributor', with_payment_and_shipping: true)

      # Relationships required for interface to work
      create(:enterprise_relationship, parent: supplier, child: coordinator, permissions_list: [:add_to_order_cycle])
      create(:enterprise_relationship, parent: distributor, child: coordinator, permissions_list: [:add_to_order_cycle])
      create(:enterprise_relationship, parent: supplier, child: distributor, permissions_list: [:add_to_order_cycle])

      # And some enterprise fees
      supplier_fee    = create(:enterprise_fee, enterprise: supplier,    name: 'Supplier fee')
      coordinator_fee = create(:enterprise_fee, enterprise: coordinator, name: 'Coord fee')
      distributor_fee = create(:enterprise_fee, enterprise: distributor, name: 'Distributor fee')

      # When I go to the new order cycle page
      login_to_admin_section
      click_link 'Order Cycles'
      click_link 'New Order Cycle'

      # Select a coordinator since there are two available
      select2_select 'My coordinator', from: 'coordinator_id'
      click_button "Continue >"

      # And I fill in the basic fields
      fill_in 'order_cycle_name', with: 'Plums & Avos'
      fill_in 'order_cycle_orders_open_at', with: order_cycle_opening_time
      fill_in 'order_cycle_orders_close_at', with: order_cycle_closing_time

      # And I add a coordinator fee
      click_button 'Add coordinator fee'
      select 'Coord fee', from: 'order_cycle_coordinator_fee_0_id'

      # I should not be able to add a blank supplier
      page.should have_select 'new_supplier_id', selected: ''
      page.should have_button 'Add supplier', disabled: true

      # And I add a supplier and some products
      select 'My supplier', from: 'new_supplier_id'
      click_button 'Add supplier'
      fill_in 'order_cycle_incoming_exchange_0_receival_instructions', with: 'receival instructions'
      page.find('table.exchanges tr.supplier td.products').click
      check "order_cycle_incoming_exchange_0_variants_#{v1.id}"
      check "order_cycle_incoming_exchange_0_variants_#{v2.id}"

      # I should not be able to re-add the supplier
      page.should_not have_select 'new_supplier_id', with_options: ['My supplier']
      page.should have_button 'Add supplier', disabled: true
      page.all("td.supplier_name").map(&:text).should == ['My supplier']

      # And I add a supplier fee
      within("tr.supplier-#{supplier.id}") { click_button 'Add fee' }
      select 'My supplier',  from: 'order_cycle_incoming_exchange_0_enterprise_fees_0_enterprise_id'
      select 'Supplier fee', from: 'order_cycle_incoming_exchange_0_enterprise_fees_0_enterprise_fee_id'

      # And I add a distributor with the same products
      select 'My distributor', from: 'new_distributor_id'
      click_button 'Add distributor'

      fill_in 'order_cycle_outgoing_exchange_0_pickup_time', with: 'pickup time'
      fill_in 'order_cycle_outgoing_exchange_0_pickup_instructions', with: 'pickup instructions'

      page.find('table.exchanges tr.distributor td.products').click
      check "order_cycle_outgoing_exchange_0_variants_#{v1.id}"
      check "order_cycle_outgoing_exchange_0_variants_#{v2.id}"

      page.find('table.exchanges tr.distributor td.tags').click
      within ".exchange-tags" do
        find(:css, "tags-input .tags input").set "wholesale\n"
      end

      # And I add a distributor fee
      within("tr.distributor-#{distributor.id}") { click_button 'Add fee' }
      select 'My distributor',  from: 'order_cycle_outgoing_exchange_0_enterprise_fees_0_enterprise_id'
      select 'Distributor fee', from: 'order_cycle_outgoing_exchange_0_enterprise_fees_0_enterprise_fee_id'

      # And I click Create
      click_button 'Create'

      # Then my order cycle should have been created
      page.should have_content 'Your order cycle has been created.'

      oc = OrderCycle.last

      page.should have_selector 'a', text: 'Plums & Avos'
      page.should have_input "oc#{oc.id}[orders_open_at]", value: order_cycle_opening_time
      page.should have_input "oc#{oc.id}[orders_close_at]", value: order_cycle_closing_time
      page.should have_content 'My coordinator'

      page.should have_selector 'td.producers', text: 'My supplier'
      page.should have_selector 'td.shops', text: 'My distributor'

      # And it should have some fees
      oc.exchanges.incoming.first.enterprise_fees.should == [supplier_fee]
      oc.coordinator_fees.should                         == [coordinator_fee]
      oc.exchanges.outgoing.first.enterprise_fees.should == [distributor_fee]

      # And it should have some variants selected
      oc.exchanges.first.variants.count.should == 2
      oc.exchanges.last.variants.count.should == 2

      # And my receival and pickup time and instructions should have been saved
      exchange = oc.exchanges.incoming.first
      exchange.receival_instructions.should == 'receival instructions'

      exchange = oc.exchanges.outgoing.first
      exchange.pickup_time.should == 'pickup time'
      exchange.pickup_instructions.should == 'pickup instructions'
      exchange.tag_list.should == ['wholesale']
    end

    scenario "updating an order cycle", js: true do
      # Given an order cycle with all the settings
      oc = create(:order_cycle)
      initial_variants = oc.variants.sort_by(&:id)

      # And a coordinating, supplying and distributing enterprise with some products with variants
      coordinator = oc.coordinator
      supplier = create(:supplier_enterprise, name: 'My supplier')
      distributor = create(:distributor_enterprise, name: 'My distributor', with_payment_and_shipping: true)
      product = create(:product, supplier: supplier)
      v1 = create(:variant, product: product)
      v2 = create(:variant, product: product)

      # Relationships required for interface to work
      create(:enterprise_relationship, parent: supplier, child: coordinator, permissions_list: [:add_to_order_cycle])
      create(:enterprise_relationship, parent: distributor, child: coordinator, permissions_list: [:add_to_order_cycle])
      create(:enterprise_relationship, parent: supplier, child: distributor, permissions_list: [:add_to_order_cycle])

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
      fill_in 'order_cycle_orders_open_at', with: order_cycle_opening_time
      fill_in 'order_cycle_orders_close_at', with: order_cycle_closing_time

      # CAN'T CHANGE COORDINATOR ANYMORE
      # select 'My coordinator', from: 'order_cycle_coordinator_id'

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
      page.all("table.exchanges tr.supplier td.products").each { |e| e.click }

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
      fill_in 'order_cycle_outgoing_exchange_2_pickup_time', with: 'New time 2'
      fill_in 'order_cycle_outgoing_exchange_2_pickup_instructions', with: 'New instructions 2'

      page.find("table.exchanges tr.distributor-#{distributor.id} td.tags").click
      within ".exchange-tags" do
        find(:css, "tags-input .tags input").set "wholesale\n"
      end

      page.all("table.exchanges tr.distributor td.products").each { |e| e.click }

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
      expect(page).to have_selector "#save-bar"
      click_button 'Update and Close'

      # Then my order cycle should have been updated
      page.should have_content 'Your order cycle has been updated.'

      oc = OrderCycle.last

      page.should have_selector 'a', text: 'Plums & Avos'
      page.should have_input "oc#{oc.id}[orders_open_at]", value: order_cycle_opening_time
      page.should have_input "oc#{oc.id}[orders_close_at]", value: order_cycle_closing_time
      page.should have_content coordinator.name

      page.should have_selector 'td.producers', text: 'My supplier'
      page.should have_selector 'td.shops', text: 'My distributor'

      # And my coordinator fees should have been configured
      oc.coordinator_fee_ids.should match_array [coordinator_fee1.id, coordinator_fee2.id]

      # And my supplier fees should have been configured
      oc.exchanges.incoming.last.enterprise_fee_ids.should == [supplier_fee2.id]

      # And my distributor fees should have been configured
      oc.exchanges.outgoing.last.enterprise_fee_ids.should == [distributor_fee2.id]

      # And my tags should have been save
      oc.exchanges.outgoing.last.tag_list.should == ['wholesale']

      # And it should have some variants selected
      selected_initial_variants = initial_variants.take initial_variants.size - 1
      oc.variants.map(&:id).should match_array (selected_initial_variants.map(&:id) + [v1.id, v2.id])

      # And the collection details should have been updated
      oc.exchanges.where(pickup_time: 'New time 0', pickup_instructions: 'New instructions 0').should be_present
      oc.exchanges.where(pickup_time: 'New time 1', pickup_instructions: 'New instructions 1').should be_present
    end
  end

  scenario "editing an order cycle" do
    # Given an order cycle with all the settings
    oc = create(:order_cycle)
    oc.suppliers.first.update_attribute :name, 'AAA'
    oc.suppliers.last.update_attribute :name, 'ZZZ'
    oc.distributors.first.update_attribute :name, 'AAAA'
    oc.distributors.last.update_attribute :name, 'ZZZZ'

    # When I edit it
    login_to_admin_section
    click_link 'Order Cycles'
    click_link oc.name
    wait_until { page.find('#order_cycle_name').value.present? }

    # Then I should see the basic settings
    page.find('#order_cycle_name').value.should == oc.name
    page.find('#order_cycle_orders_open_at').value.should == oc.orders_open_at.to_s
    page.find('#order_cycle_orders_close_at').value.should == oc.orders_close_at.to_s
    page.should have_content "COORDINATOR #{oc.coordinator.name}"

    # And I should see the suppliers
    page.should have_selector 'td.supplier_name', :text => oc.suppliers.first.name
    page.should have_selector 'td.supplier_name', :text => oc.suppliers.last.name

    page.should have_field 'order_cycle_incoming_exchange_0_receival_instructions', with: 'instructions 0'
    page.should have_field 'order_cycle_incoming_exchange_1_receival_instructions', with: 'instructions 1'

    # And the suppliers should have products
    page.all('table.exchanges tbody tr.supplier').each_with_index do |row, i|
      row.find('td.products').click

      products_panel = page.all('table.exchanges tr.panel-row .exchange-supplied-products').select { |r| r.visible? }.first
      products_panel.should have_selector "input[name='order_cycle_incoming_exchange_#{i}_select_all_variants']"

      row.find('td.products').click
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
    page.all('table.exchanges tbody tr.distributor').each_with_index do |row, i|
      row.find('td.products').click

      products_panel = page.all('table.exchanges tr.panel-row .exchange-distributed-products').select { |r| r.visible? }.first
      products_panel.should have_selector "input[name='order_cycle_outgoing_exchange_#{i}_select_all_variants']"

      row.find('td.products').click
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

  scenario "updating many order cycle opening/closing times at once", js: true do
    # Given three order cycles
    oc1 = create(:simple_order_cycle)
    oc2 = create(:simple_order_cycle)
    oc3 = create(:simple_order_cycle, orders_open_at: Time.zone.local(2040, 12, 12, 12, 12, 12))

    # When I go to the order cycles page
    login_to_admin_section
    click_link 'Order Cycles'

    # And I fill in some new opening/closing times and save them
    within("tr.order-cycle-#{oc1.id}") do
      all('input').first.set '2040-12-01 12:00:00'
      all('input').last.set '2040-12-01 12:00:01'
    end

    within("tr.order-cycle-#{oc2.id}") do
      all('input').first.set '2040-12-01 12:00:02'
      all('input').last.set '2040-12-01 12:00:03'
    end

    # And I fill in a time using the datepicker
    within("tr.order-cycle-#{oc3.id}") do
      # When I trigger the datepicker
      find('img.ui-datepicker-trigger', match: :first).click
    end

    within("#ui-datepicker-div") do
      # Then it should display the correct date/time
      expect(page).to have_selector 'span.ui-datepicker-month', text: 'DECEMBER'
      expect(page).to have_selector 'span.ui-datepicker-year', text: '2040'
      expect(page).to have_selector 'a.ui-state-active', text: '12'

      # When I fill in a new date/time
      click_link '1'
      click_button 'Done'
    end

    within("tr.order-cycle-#{oc3.id}") do
      # Then that date/time should appear on the form
      expect(all('input').first.value).to eq '2040-12-01 00:00'

      # Manually fill out time
      all('input').first.set '2040-12-01 12:00:04'
      all('input').last.set '2040-12-01 12:00:05'
    end

    click_button 'Save Changes'

    # Then my times should have been saved
    expect(page).to have_selector "#save-bar", text: "Order cycles have been updated."
    OrderCycle.order('id ASC').map { |oc| oc.orders_open_at.sec }.should == [0, 2, 4]
    OrderCycle.order('id ASC').map { |oc| oc.orders_close_at.sec }.should == [1, 3, 5]
  end

  scenario "cloning an order cycle" do
    # Given an order cycle
    oc = create(:simple_order_cycle)

    # When I clone it
    login_to_admin_section
    click_link 'Order Cycles'
    within "tr.order-cycle-#{oc.id}" do
      find('a.clone-order-cycle').click
    end
    expect(flash_message).to eq "Your order cycle #{oc.name} has been cloned."

    # Then I should have clone of the order cycle
    occ = OrderCycle.last
    expect(occ.name).to eq "COPY OF #{oc.name}"
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
    within("table.exchanges tbody tr.supplier") { page.find('td.products').click }
    page.find("#order_cycle_incoming_exchange_0_variants_#{p.master.id}", visible: true).trigger('click') # uncheck
    click_button "Update"

    # Then the master variant should have been removed from all exchanges
    page.should have_content "Your order cycle has been updated."
    ExchangeVariant.where(exchange_id: exchange_ids, variant_id: p.master.id).should be_empty
  end


  describe "ensuring that hubs in order cycles have valid shipping and payment methods" do
    context "when they don't" do
      let(:hub) { create(:distributor_enterprise) }
      let!(:oc) { create(:simple_order_cycle, distributors: [hub]) }

      it "displays a warning on the dashboard" do
        login_to_admin_section
        page.should have_content "The hub #{hub.name} is listed in an active order cycle, but does not have valid shipping and payment methods. Until you set these up, customers will not be able to shop at this hub."
      end

      it "displays a warning on the order cycles screen" do
        login_to_admin_section
        visit admin_order_cycles_path
        page.should have_content "The hub #{hub.name} is listed in an active order cycle, but does not have valid shipping and payment methods. Until you set these up, customers will not be able to shop at this hub."
      end
    end

    context "when they do" do
      let(:hub) { create(:distributor_enterprise, with_payment_and_shipping: true) }
      let!(:oc) { create(:simple_order_cycle, distributors: [hub]) }

      it "does not display the warning on the dashboard" do
        login_to_admin_section
        page.should_not have_content "does not have valid shipping and payment methods"
      end
    end
  end

  context "as an enterprise user" do
    let!(:supplier_managed) { create(:supplier_enterprise, name: 'Managed supplier') }
    let!(:supplier_unmanaged) { create(:supplier_enterprise, name: 'Unmanaged supplier') }
    let!(:supplier_permitted) { create(:supplier_enterprise, name: 'Permitted supplier') }
    let!(:distributor_managed) { create(:distributor_enterprise, name: 'Managed distributor') }
    let!(:distributor_unmanaged) { create(:distributor_enterprise, name: 'Unmanaged Distributor') }
    let!(:distributor_permitted) { create(:distributor_enterprise, name: 'Permitted distributor') }
    let!(:distributor_managed_fee) { create(:enterprise_fee, enterprise: distributor_managed, name: 'Managed distributor fee') }
    let!(:shipping_method) { create(:shipping_method, distributors: [distributor_managed, distributor_unmanaged, distributor_permitted]) }
    let!(:payment_method) { create(:payment_method, distributors: [distributor_managed, distributor_unmanaged, distributor_permitted]) }
    let!(:product_managed) { create(:product, supplier: supplier_managed) }
    let!(:variant_managed) { product_managed.variants.first }
    let!(:product_permitted) { create(:product, supplier: supplier_permitted) }
    let!(:variant_permitted) { product_permitted.variants.first }

    before do
      # Relationships required for interface to work
      # Both suppliers allow both managed distributor to distribute their products (and add them to the order cycle)
      create(:enterprise_relationship, parent: supplier_managed, child: distributor_managed, permissions_list: [:add_to_order_cycle])
      create(:enterprise_relationship, parent: supplier_permitted, child: distributor_managed, permissions_list: [:add_to_order_cycle])

      # Both suppliers allow permitted distributor to distribute their products
      create(:enterprise_relationship, parent: supplier_managed, child: distributor_permitted, permissions_list: [:add_to_order_cycle])
      create(:enterprise_relationship, parent: supplier_permitted, child: distributor_permitted, permissions_list: [:add_to_order_cycle])

      # Permitted distributor can be added to the order cycle
      create(:enterprise_relationship, parent: distributor_permitted, child: distributor_managed, permissions_list: [:add_to_order_cycle])
    end

    context "that is a manager of the coordinator" do
      before do
        @new_user = create_enterprise_user
        @new_user.enterprise_roles.build(enterprise: supplier_managed).save
        @new_user.enterprise_roles.build(enterprise: distributor_managed).save

        login_to_admin_as @new_user
      end

      scenario "viewing a list of order cycles I am coordinating" do
        oc_user_coordinating = create(:simple_order_cycle, { suppliers: [supplier_managed, supplier_unmanaged], coordinator: distributor_managed, distributors: [distributor_managed, distributor_unmanaged], name: 'Order Cycle 1' } )
        oc_for_other_user = create(:simple_order_cycle, { coordinator: supplier_unmanaged, name: 'Order Cycle 2' } )

        click_link "Order Cycles"

        # I should see only the order cycle I am coordinating
        page.should have_content oc_user_coordinating.name
        page.should_not have_content oc_for_other_user.name

        # The order cycle should show all enterprises in the order cycle
        page.should have_selector 'td.producers', text: supplier_managed.name
        page.should have_selector 'td.shops', text: distributor_managed.name
        page.should have_selector 'td.producers', text: supplier_unmanaged.name
        page.should have_selector 'td.shops', text: distributor_unmanaged.name
      end

      scenario "creating a new order cycle" do
        # Make the page long enough to avoid the save bar overlaying the form
        page.driver.resize(1280, 2000)

        click_link "Order Cycles"
        click_link 'New Order Cycle'

        fill_in 'order_cycle_name', with: 'My order cycle'
        fill_in 'order_cycle_orders_open_at', with: '2040-11-06 06:00:00'
        fill_in 'order_cycle_orders_close_at', with: '2040-11-13 17:00:00'

        select 'Managed supplier', from: 'new_supplier_id'
        click_button 'Add supplier'
        select 'Permitted supplier', from: 'new_supplier_id'
        click_button 'Add supplier'

        select_incoming_variant supplier_managed, 0, variant_managed
        select_incoming_variant supplier_permitted, 1, variant_permitted

        click_button 'Add coordinator fee'
        select 'Managed distributor fee', from: 'order_cycle_coordinator_fee_0_id'

        select 'Managed distributor', from: 'new_distributor_id'
        click_button 'Add distributor'
        select 'Permitted distributor', from: 'new_distributor_id'
        click_button 'Add distributor'

        fill_in 'order_cycle_outgoing_exchange_0_pickup_time', with: 'pickup time'
        fill_in 'order_cycle_outgoing_exchange_0_pickup_instructions', with: 'pickup instructions'
        fill_in 'order_cycle_outgoing_exchange_1_pickup_time', with: 'pickup time 2'
        fill_in 'order_cycle_outgoing_exchange_1_pickup_instructions', with: 'pickup instructions'

        # Should only have suppliers / distributors listed which the user is managing or
        # has E2E permission to add products to order cycles
        page.should_not have_select 'new_supplier_id', with_options: [supplier_unmanaged.name]
        page.should_not have_select 'new_distributor_id', with_options: [distributor_unmanaged.name]

        [distributor_unmanaged.name, supplier_managed.name, supplier_unmanaged.name].each do |enterprise_name|
          page.should_not have_select 'order_cycle_coordinator_id', with_options: [enterprise_name]
        end

        page.find("table.exchanges tr.distributor-#{distributor_managed.id} td.tags").click
        within ".exchange-tags" do
          find(:css, "tags-input .tags input").set "wholesale\n"
        end

        click_button 'Create'

        flash_message.should == "Your order cycle has been created."
        order_cycle = OrderCycle.find_by_name('My order cycle')
        order_cycle.suppliers.should match_array [supplier_managed, supplier_permitted]
        order_cycle.coordinator.should == distributor_managed
        order_cycle.distributors.should match_array [distributor_managed, distributor_permitted]
        exchange = order_cycle.exchanges.outgoing.to_enterprise(distributor_managed).first
        exchange.tag_list.should == ["wholesale"]
      end

      scenario "editing an order cycle we can see (and for now, edit) all exchanges in the order cycle" do
        # TODO: when we add the editable scope to variant permissions, we should test that
        # exchanges with enterprises who have not granted P-OC to the coordinator are not
        # editable, but at this point we cannot distiguish between visible and editable
        # variants.

        oc = create(:simple_order_cycle, { suppliers: [supplier_managed, supplier_permitted, supplier_unmanaged], coordinator: distributor_managed, distributors: [distributor_managed, distributor_permitted, distributor_unmanaged], name: 'Order Cycle 1' } )

        visit edit_admin_order_cycle_path(oc)

        fill_in 'order_cycle_name', with: 'Coordinated'

        # I should be able to see but not edit exchanges for supplier_unmanaged or distributor_unmanaged
        expect(page).to have_selector "tr.supplier-#{supplier_managed.id}"
        expect(page).to have_selector "tr.supplier-#{supplier_permitted.id}"
        expect(page).to have_selector "tr.supplier-#{supplier_unmanaged.id}"
        expect(page).to have_selector 'tr.supplier', count: 3

        expect(page).to have_selector "tr.distributor-#{distributor_managed.id}"
        expect(page).to have_selector "tr.distributor-#{distributor_permitted.id}"
        expect(page).to have_selector "tr.distributor-#{distributor_unmanaged.id}"
        expect(page).to have_selector 'tr.distributor', count: 3

        # When I save, then those exchanges should remain
        click_button 'Update'
        page.should have_content "Your order cycle has been updated."

        oc.reload
        oc.suppliers.should match_array [supplier_managed, supplier_permitted, supplier_unmanaged]
        oc.coordinator.should == distributor_managed
        oc.distributors.should match_array [distributor_managed, distributor_permitted, distributor_unmanaged]
      end

      scenario "editing an order cycle" do
        oc = create(:simple_order_cycle, { suppliers: [supplier_managed, supplier_permitted, supplier_unmanaged], coordinator: distributor_managed, distributors: [distributor_managed, distributor_permitted, distributor_unmanaged], name: 'Order Cycle 1' } )

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
        oc.coordinator.should == distributor_managed
        oc.distributors.should == [distributor_unmanaged]
      end

      scenario "cloning an order cycle" do
        oc = create(:simple_order_cycle, coordinator: distributor_managed)

        click_link "Order Cycles"
        within "tr.order-cycle-#{oc.id}" do
          find('a.clone-order-cycle').click
        end
        expect(flash_message).to eq "Your order cycle #{oc.name} has been cloned."

        # Then I should have clone of the order cycle
        occ = OrderCycle.last
        occ.name.should == "COPY OF #{oc.name}"
      end
    end

    context "that is a manager of a participating producer" do
      let(:new_user) { create_enterprise_user }

      before do
        new_user.enterprise_roles.build(enterprise: supplier_managed).save
        login_to_admin_as new_user
      end

      scenario "editing an order cycle" do
        oc = create(:simple_order_cycle, { suppliers: [supplier_managed, supplier_permitted, supplier_unmanaged], coordinator: distributor_managed, distributors: [distributor_managed, distributor_permitted, distributor_unmanaged], name: 'Order Cycle 1' } )
        v1 = create(:variant, product: create(:product, supplier: supplier_managed) )
        v2 = create(:variant, product: create(:product, supplier: supplier_managed) )

        # Incoming exchange
        ex_in = oc.exchanges.where(sender_id: supplier_managed, receiver_id: distributor_managed, incoming: true).first
        ex_in.update_attributes(variant_ids: [v1.id, v2.id])

        # Outgoing exchange
        ex_out = oc.exchanges.where(sender_id: distributor_managed, receiver_id: distributor_managed, incoming: false).first
        ex_out.update_attributes(variant_ids: [v1.id, v2.id])

        # Stub editable_variants_for_outgoing_exchanges method so we can test permissions
        serializer = Api::Admin::OrderCycleSerializer.new(oc, current_user: new_user)
        allow(Api::Admin::OrderCycleSerializer).to receive(:new) { serializer }
        allow(serializer).to receive(:editable_variants_for_outgoing_exchanges) do
          { "#{distributor_managed.id}" => [v1.id] }
        end

        visit edit_admin_order_cycle_path(oc)

        # I should only see exchanges for supplier_managed AND
        # distributor_managed and distributor_permitted (who I have given permission to) AND
        # and distributor_unmanaged (who distributes my products)
        expect(page).to have_selector "tr.supplier-#{supplier_managed.id}"
        expect(page).to have_selector 'tr.supplier', count: 1

        expect(page).to have_selector "tr.distributor-#{distributor_managed.id}"
        expect(page).to have_selector "tr.distributor-#{distributor_permitted.id}"
        expect(page).to have_selector 'tr.distributor', count: 2

        # Open the products list for managed_supplier's incoming exchange
        within "tr.distributor-#{distributor_managed.id}" do
          page.find("td.products").click
        end

        # I should be able to see and toggle v1
        expect(page).to have_checked_field "order_cycle_outgoing_exchange_0_variants_#{v1.id}", disabled: false
        uncheck "order_cycle_outgoing_exchange_0_variants_#{v1.id}"

        # I should be able to see but not toggle v2, because I don't have permission
        expect(page).to have_checked_field "order_cycle_outgoing_exchange_0_variants_#{v2.id}", disabled: true

        page.should_not have_selector "table.exchanges tr.distributor-#{distributor_managed.id} td.tags"

        # When I save, any exchanges that I can't manage remain
        click_button 'Update'
        page.should have_content "Your order cycle has been updated."

        oc.reload
        oc.suppliers.should match_array [supplier_managed, supplier_permitted, supplier_unmanaged]
        oc.coordinator.should == distributor_managed
        oc.distributors.should match_array [distributor_managed, distributor_permitted, distributor_unmanaged]
      end
    end

    context "that is the manager of a participating hub" do
      let(:my_distributor) { create(:distributor_enterprise) }
      let(:new_user) { create_enterprise_user }

      before do
        create(:enterprise_relationship, parent: supplier_managed, child: my_distributor, permissions_list: [:add_to_order_cycle])

        new_user.enterprise_roles.build(enterprise: my_distributor).save
        login_to_admin_as new_user
      end

      scenario "editing an order cycle" do
        oc = create(:simple_order_cycle, { suppliers: [supplier_managed, supplier_permitted, supplier_unmanaged], coordinator: distributor_managed, distributors: [my_distributor, distributor_managed, distributor_permitted, distributor_unmanaged], name: 'Order Cycle 1' } )
        v1 = create(:variant, product: create(:product, supplier: supplier_managed) )
        v2 = create(:variant, product: create(:product, supplier: supplier_managed) )

        # Incoming exchange
        ex_in = oc.exchanges.where(sender_id: supplier_managed, receiver_id: distributor_managed, incoming: true).first
        ex_in.update_attributes(variant_ids: [v1.id, v2.id])

        # Outgoing exchange
        ex_out = oc.exchanges.where(sender_id: distributor_managed, receiver_id: my_distributor, incoming: false).first
        ex_out.update_attributes(variant_ids: [v1.id, v2.id])

        # Stub editable_variants_for_incoming_exchanges method so we can test permissions
        serializer = Api::Admin::OrderCycleSerializer.new(oc, current_user: new_user)
        allow(Api::Admin::OrderCycleSerializer).to receive(:new) { serializer }
        allow(serializer).to receive(:editable_variants_for_incoming_exchanges) do
          { "#{supplier_managed.id}" => [v1.id] }
        end

        visit edit_admin_order_cycle_path(oc)

        # I should see exchanges for my_distributor, and the incoming exchanges supplying the variants in it
        expect(page).to have_selector "tr.supplier-#{supplier_managed.id}"
        expect(page).to have_selector 'tr.supplier', count: 1

        expect(page).to have_selector "tr.distributor-#{my_distributor.id}"
        expect(page).to have_selector 'tr.distributor', count: 1

        # Open the products list for managed_supplier's incoming exchange
        within "tr.supplier-#{supplier_managed.id}" do
          page.find("td.products").click
        end

        # I should be able to see and toggle v1
        expect(page).to have_checked_field "order_cycle_incoming_exchange_0_variants_#{v1.id}", disabled: false
        uncheck "order_cycle_incoming_exchange_0_variants_#{v1.id}"

        # I should be able to see but not toggle v2, because I don't have permission
        expect(page).to have_checked_field "order_cycle_incoming_exchange_0_variants_#{v2.id}", disabled: true

        page.should have_selector "table.exchanges tr.distributor-#{my_distributor.id} td.tags"

        # When I save, any exchange that I can't manage remains
        click_button 'Update'
        page.should have_content "Your order cycle has been updated."

        oc.reload
        oc.suppliers.should match_array [supplier_managed, supplier_permitted, supplier_unmanaged]
        oc.coordinator.should == distributor_managed
        oc.distributors.should match_array [my_distributor, distributor_managed, distributor_permitted, distributor_unmanaged]
      end
    end
  end


  describe "simplified interface for enterprise users selling only their own produce" do
    let(:user) { create_enterprise_user }
    let(:enterprise) { create(:enterprise, is_primary_producer: true, sells: 'own') }
    let!(:p1) { create(:simple_product, supplier: enterprise) }
    let!(:p2) { create(:simple_product, supplier: enterprise) }
    let!(:p3) { create(:simple_product, supplier: enterprise) }
    let!(:v1) { p1.variants.first }
    let!(:v2) { p2.variants.first }
    let!(:v3) { p3.variants.first }
    let!(:fee) { create(:enterprise_fee, enterprise: enterprise, name: 'Coord fee') }

    before do
      user.enterprise_roles.create! enterprise: enterprise
      login_to_admin_as user
    end

    it "shows me an index of order cycles without enterprise columns" do
      create(:simple_order_cycle, coordinator: enterprise)
      visit admin_order_cycles_path
      page.should_not have_selector 'th', text: 'SUPPLIERS'
      page.should_not have_selector 'th', text: 'COORDINATOR'
      page.should_not have_selector 'th', text: 'DISTRIBUTORS'
    end

    it "creates order cycles", js: true do
      # Make the page long enough to avoid the save bar overlaying the form
      page.driver.resize(1280, 2000)

      # When I go to the new order cycle page
      visit admin_order_cycles_path
      click_link 'New Order Cycle'

      # And I fill in the basic fields
      fill_in 'order_cycle_name', with: 'Plums & Avos'
      fill_in 'order_cycle_orders_open_at', with: '2040-10-17 06:00:00'
      fill_in 'order_cycle_orders_close_at', with: '2040-10-24 17:00:00'
      fill_in 'order_cycle_outgoing_exchange_0_pickup_time', with: 'pickup time'
      fill_in 'order_cycle_outgoing_exchange_0_pickup_instructions', with: 'pickup instructions'

      # Then my products / variants should already be selected
      page.should have_checked_field "order_cycle_incoming_exchange_0_variants_#{v1.id}"
      page.should have_checked_field "order_cycle_incoming_exchange_0_variants_#{v2.id}"
      page.should have_checked_field "order_cycle_incoming_exchange_0_variants_#{v3.id}"

      # When I unselect a product
      uncheck "order_cycle_incoming_exchange_0_variants_#{v2.id}"

      # And I add a fee and save
      click_button 'Add coordinator fee'
      click_button 'Add coordinator fee'
      click_link 'order_cycle_coordinator_fee_1_remove'
      page.should     have_select 'order_cycle_coordinator_fee_0_id'
      page.should_not have_select 'order_cycle_coordinator_fee_1_id'

      select 'Coord fee', from: 'order_cycle_coordinator_fee_0_id'
      click_button 'Create'

      # Then my order cycle should have been created
      page.should have_content 'Your order cycle has been created.'

      oc = OrderCycle.last

      page.should have_selector 'a', text: 'Plums & Avos'
      page.should have_input "oc#{oc.id}[orders_open_at]", value: Time.zone.local(2040, 10, 17, 06, 00, 00).strftime("%F %T %z")
      page.should have_input "oc#{oc.id}[orders_close_at]", value: Time.zone.local(2040, 10, 24, 17, 00, 00).strftime("%F %T %z")

      # And it should have some variants selected
      oc.exchanges.incoming.first.variants.count.should == 2
      oc.exchanges.outgoing.first.variants.count.should == 2

      # And it should have the fee
      oc.coordinator_fees.should == [fee]

      # And my pickup time and instructions should have been saved
      ex = oc.exchanges.outgoing.first
      ex.pickup_time.should == 'pickup time'
      ex.pickup_instructions.should == 'pickup instructions'
    end

    scenario "editing an order cycle" do
      # Given an order cycle with pickup time and instructions
      fee = create(:enterprise_fee, name: 'my fee', enterprise: enterprise)
      oc = create(:simple_order_cycle, suppliers: [enterprise], coordinator: enterprise, distributors: [enterprise], variants: [v1], coordinator_fees: [fee])
      ex = oc.exchanges.outgoing.first
      ex.update_attributes! pickup_time: 'pickup time', pickup_instructions: 'pickup instructions'

      # When I edit it
      login_to_admin_section
      click_link 'Order Cycles'
      click_link oc.name
      wait_until { page.find('#order_cycle_name').value.present? }

      # Then I should see the basic settings
      page.should have_field 'order_cycle_name', with: oc.name
      page.should have_field 'order_cycle_orders_open_at', with: oc.orders_open_at.to_s
      page.should have_field 'order_cycle_orders_close_at', with: oc.orders_close_at.to_s
      page.should have_field 'order_cycle_outgoing_exchange_0_pickup_time', with: 'pickup time'
      page.should have_field 'order_cycle_outgoing_exchange_0_pickup_instructions', with: 'pickup instructions'

      # And I should see the products
      page.should have_checked_field   "order_cycle_incoming_exchange_0_variants_#{v1.id}"
      page.should have_unchecked_field "order_cycle_incoming_exchange_0_variants_#{v2.id}"
      page.should have_unchecked_field "order_cycle_incoming_exchange_0_variants_#{v3.id}"

      # And I should see the coordinator fees
      page.should have_select 'order_cycle_coordinator_fee_0_id', selected: 'my fee'
    end

    scenario "updating an order cycle" do
      # Given an order cycle with pickup time and instructions
      fee1 = create(:enterprise_fee, name: 'my fee', enterprise: enterprise)
      fee2 = create(:enterprise_fee, name: 'that fee', enterprise: enterprise)
      oc = create(:simple_order_cycle, suppliers: [enterprise], coordinator: enterprise, distributors: [enterprise], variants: [v1], coordinator_fees: [fee1])
      ex = oc.exchanges.outgoing.first
      ex.update_attributes! pickup_time: 'pickup time', pickup_instructions: 'pickup instructions'

      # When I edit it
      login_to_admin_section
      visit edit_admin_order_cycle_path oc
      wait_until { page.find('#order_cycle_name').value.present? }

      # And I fill in the basic fields
      fill_in 'order_cycle_name', with: 'Plums & Avos'
      fill_in 'order_cycle_orders_open_at', with: '2040-10-17 06:00:00'
      fill_in 'order_cycle_orders_close_at', with: '2040-10-24 17:00:00'
      fill_in 'order_cycle_outgoing_exchange_0_pickup_time', with: 'xy'
      fill_in 'order_cycle_outgoing_exchange_0_pickup_instructions', with: 'zzy'

      # And I make some product selections
      uncheck "order_cycle_incoming_exchange_0_variants_#{v1.id}"
      check   "order_cycle_incoming_exchange_0_variants_#{v2.id}"
      check   "order_cycle_incoming_exchange_0_variants_#{v3.id}"
      uncheck "order_cycle_incoming_exchange_0_variants_#{v3.id}"

      # And I select some fees and update
      click_link 'order_cycle_coordinator_fee_0_remove'
      page.should_not have_select 'order_cycle_coordinator_fee_0_id'
      click_button 'Add coordinator fee'
      select 'that fee', from: 'order_cycle_coordinator_fee_0_id'

      # When I update, or update and close, both work
      click_button 'Update'
      page.should have_content 'Your order cycle has been updated.'

      fill_in 'order_cycle_outgoing_exchange_0_pickup_instructions', with: 'yyz'
      click_button 'Update and Close'

      # Then my order cycle should have been updated
      page.should have_content 'Your order cycle has been updated.'
      oc = OrderCycle.last

      page.should have_selector 'a', text: 'Plums & Avos'
      page.should have_input "oc#{oc.id}[orders_open_at]", value: Time.zone.local(2040, 10, 17, 06, 00, 00).strftime("%F %T %z")
      page.should have_input "oc#{oc.id}[orders_close_at]", value: Time.zone.local(2040, 10, 24, 17, 00, 00).strftime("%F %T %z")

      # And it should have a variant selected
      oc.exchanges.incoming.first.variants.should == [v2]
      oc.exchanges.outgoing.first.variants.should == [v2]

      # And it should have the fee
      oc.coordinator_fees.should == [fee2]

      # And my pickup time and instructions should have been saved
      ex = oc.exchanges.outgoing.first
      ex.pickup_time.should == 'xy'
      ex.pickup_instructions.should == 'yyz'
    end
  end

  scenario "deleting an order cycle" do
    create(:simple_order_cycle, name: "Translusent Berries")
    login_to_admin_section
    click_link 'Order Cycles'
    page.should have_content("Translusent Berries")
    first('a.delete-order-cycle').click
    page.should_not have_content("Translusent Berries")
  end


  private

  def select_incoming_variant(supplier, exchange_no, variant)
    page.find("table.exchanges tr.supplier-#{supplier.id} td.products").click
    check "order_cycle_incoming_exchange_#{exchange_no}_variants_#{variant.id}"
  end
end
