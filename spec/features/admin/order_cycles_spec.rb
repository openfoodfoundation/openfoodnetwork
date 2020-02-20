require 'spec_helper'

feature '
    As an administrator
    I want to manage order cycles
', js: true do
  include AdminHelper
  include AuthenticationWorkflow
  include WebHelper

  scenario "listing and filtering order cycles" do
    # Given some order cycles (created in an arbitrary order)
    oc4 = create(:simple_order_cycle, name: 'oc4',
                                      orders_open_at: 2.days.from_now, orders_close_at: 1.month.from_now)
    oc2 = create(:simple_order_cycle, name: 'oc2', orders_close_at: 1.month.from_now)
    oc6 = create(:simple_order_cycle, name: 'oc6',
                                      orders_open_at: 1.month.ago, orders_close_at: 3.weeks.ago)
    oc3 = create(:simple_order_cycle, name: 'oc3',
                                      orders_open_at: 1.day.from_now, orders_close_at: 1.month.from_now)
    oc5 = create(:simple_order_cycle, name: 'oc5',
                                      orders_open_at: 1.month.ago, orders_close_at: 2.weeks.ago)
    oc1 = create(:order_cycle, name: 'oc1')
    oc0 = create(:simple_order_cycle, name: 'oc0',
                                      orders_open_at: nil, orders_close_at: nil)
    oc7 = create(:simple_order_cycle, name: 'oc7',
                                      orders_open_at: 2.months.ago, orders_close_at: 5.weeks.ago)
    schedule1 = create(:schedule, name: 'Schedule1', order_cycles: [oc1, oc3])
    create(:proxy_order, subscription: create(:subscription, schedule: schedule1), order_cycle: oc1)

    # When I go to the admin order cycles page
    login_to_admin_section
    click_link 'Order Cycles'

    # Then the order cycles should be ordered correctly
    expect(page).to have_selector "#listing_order_cycles tr td:first-child", count: 7

    order_cycle_names = ["oc0", "oc1", "oc2", "oc3", "oc4", "oc5", "oc6"]
    expect(all("#listing_order_cycles tr td:first-child input").map(&:value)).to eq order_cycle_names

    # And the rows should have the correct classes
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc0.id}.undated"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}.open"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}.open"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc3.id}.upcoming"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc4.id}.upcoming"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc5.id}.closed"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc6.id}.closed"

    toggle_columns "Producers", "Shops"

    # And I should see all the details for an order cycle
    within('table#listing_order_cycles tbody tr:nth-child(2)') do
      # Then I should see the basic fields
      expect(page).to have_input "oc#{oc1.id}[name]", value: oc1.name
      expect(page).to have_input "oc#{oc1.id}[orders_open_at]", value: oc1.orders_open_at
      expect(page).to have_input "oc#{oc1.id}[orders_close_at]", value: oc1.orders_close_at
      expect(page).to have_content oc1.coordinator.name

      # And I should see the suppliers and distributors
      oc1.suppliers.each    { |s| expect(page).to have_content s.name }
      oc1.distributors.each { |d| expect(page).to have_content d.name }

      # And I should see the number of variants
      expect(page).to have_selector 'td.products', text: '2 variants'
    end

    # I can load more order_cycles
    expect(page).to have_no_selector "#listing_order_cycles tr.order-cycle-#{oc7.id}"
    click_button "Show 30 more days"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc7.id}"

    # I can filter order cycle by involved enterprises
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc0.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}"
    select2_select oc1.suppliers.first.name, from: "involving_filter"
    expect(page).to have_no_selector "#listing_order_cycles tr.order-cycle-#{oc0.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}"
    expect(page).to have_no_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}"
    select2_select "Any Enterprise", from: "involving_filter"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc0.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}"

    # I can filter order cycles by name
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc0.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}"
    fill_in "query", with: oc0.name
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc0.id}"
    expect(page).to have_no_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}"
    expect(page).to have_no_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}"
    fill_in "query", with: ''
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc0.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}"

    # I can filter order cycle by schedule
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc0.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc3.id}"
    select2_select schedule1.name, from: "schedule_filter"
    expect(page).to have_no_selector "#listing_order_cycles tr.order-cycle-#{oc0.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}"
    expect(page).to have_no_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc3.id}"
    select2_select 'Any Schedule', from: "schedule_filter"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc0.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc1.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc2.id}"
    expect(page).to have_selector "#listing_order_cycles tr.order-cycle-#{oc3.id}"

    # Attempting to edit dates of an open order cycle with active subscriptions
    find("#oc#{oc1.id}_orders_open_at").click
    expect(page).to have_selector "#confirm-dialog .message", text: I18n.t('admin.order_cycles.date_warning.msg', n: 1)
  end

  describe 'listing order cycles with other locales' do
    let!(:oc_de) { create(:simple_order_cycle, name: 'oc', orders_open_at: '2012-01-01 00:00') }

    around(:each) do |spec|
      I18n.locale = :de
      spec.run
      I18n.locale = :en
    end

    context 'using datepickers' do
      it "correctly opens the datepicker and changes the date field" do
        quick_login_as_admin
        visit admin_order_cycles_path

        within("tr.order-cycle-#{oc_de.id}") do
          expect(find('input.datetimepicker', match: :first).value).to start_with '2012-01-01 00:00'
          find('img.ui-datepicker-trigger', match: :first).click
        end

        within("#ui-datepicker-div") do
          expect(page).to have_selector 'a.ui-state-active', text: '1'

          click_link '30'
          find('button.ui-datepicker-close', match: :first).click
        end

        within("tr.order-cycle-#{oc_de.id}") do
          expect(find('input.datetimepicker', match: :first).value).to eq '2012-01-30 00:00'
        end
      end
    end
  end

  context "with specific time" do
    let(:order_cycle_opening_time) { Time.zone.local(2040, 11, 0o6, 0o6, 0o0, 0o0).strftime("%F %T %z") }
    let(:order_cycle_closing_time) { Time.zone.local(2040, 11, 13, 17, 0o0, 0o0).strftime("%F %T %z") }

    scenario "creating an order cycle with full interface", js: true do
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
      quick_login_as_admin
      visit admin_order_cycles_path
      click_link 'New Order Cycle'

      # Select a coordinator since there are two available
      select2_select 'My coordinator', from: 'coordinator_id'
      click_button "Continue >"

      # I cannot save before filling in the required fields
      expect(page).to have_button("Create", disabled: true)

      # The Create button is enabled once Name is entered
      fill_in 'order_cycle_name', with: 'Plums & Avos'
      expect(page).to have_button("Create", disabled: false)

      # If I fill in the basic fields
      fill_in 'order_cycle_orders_open_at', with: order_cycle_opening_time
      fill_in 'order_cycle_orders_close_at', with: order_cycle_closing_time

      # And I add a coordinator fee
      click_button 'Add coordinator fee'
      select 'Coord fee', from: 'order_cycle_coordinator_fee_0_id'

      click_button 'Create'
      expect(page).to have_content 'Your order cycle has been created.'

      # I should not be able to add a blank supplier
      expect(page).to have_select 'new_supplier_id', selected: ''
      expect(page).to have_button 'Add supplier', disabled: true

      # And I add a supplier and some products
      select 'My supplier', from: 'new_supplier_id'
      click_button 'Add supplier'
      fill_in 'order_cycle_incoming_exchange_0_receival_instructions', with: 'receival instructions'
      page.find('table.exchanges tr.supplier td.products').click
      check "order_cycle_incoming_exchange_0_variants_#{v1.id}"
      check "order_cycle_incoming_exchange_0_variants_#{v2.id}"

      # I should not be able to re-add the supplier
      expect(page).not_to have_select 'new_supplier_id', with_options: ['My supplier']
      expect(page).to have_button 'Add supplier', disabled: true
      expect(page.all("td.supplier_name").map(&:text)).to eq(['My supplier'])

      # And I add a supplier fee
      within("tr.supplier-#{supplier.id}") { click_button 'Add fee' }
      select 'My supplier',  from: 'order_cycle_incoming_exchange_0_enterprise_fees_0_enterprise_id'
      select 'Supplier fee', from: 'order_cycle_incoming_exchange_0_enterprise_fees_0_enterprise_fee_id'

      click_button 'Save and Next'

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

      click_button 'Save and Back to List'

      oc = OrderCycle.last
      toggle_columns "Producers", "Shops"

      expect(page).to have_input "oc#{oc.id}[name]", value: "Plums & Avos"
      expect(page).to have_input "oc#{oc.id}[orders_open_at]", value: order_cycle_opening_time
      expect(page).to have_input "oc#{oc.id}[orders_close_at]", value: order_cycle_closing_time
      expect(page).to have_content "My coordinator"

      expect(page).to have_selector 'td.producers', text: 'My supplier'
      expect(page).to have_selector 'td.shops', text: 'My distributor'

      # And it should have some fees
      expect(oc.exchanges.incoming.first.enterprise_fees).to eq([supplier_fee])
      expect(oc.coordinator_fees).to                         eq([coordinator_fee])
      expect(oc.exchanges.outgoing.first.enterprise_fees).to eq([distributor_fee])

      # And it should have some variants selected
      expect(oc.exchanges.first.variants.count).to eq(2)
      expect(oc.exchanges.last.variants.count).to eq(2)

      # And my receival and pickup time and instructions should have been saved
      exchange = oc.exchanges.incoming.first
      expect(exchange.receival_instructions).to eq('receival instructions')

      exchange = oc.exchanges.outgoing.first
      expect(exchange.pickup_time).to eq('pickup time')
      expect(exchange.pickup_instructions).to eq('pickup instructions')
      expect(exchange.tag_list).to eq(['wholesale'])
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
      quick_login_as_admin
      visit admin_order_cycles_path
      within "tr.order-cycle-#{oc.id}" do
        find("a.edit-order-cycle").click
      end

      wait_for_edit_form_to_load_order_cycle(oc)

      # And I update it
      fill_in 'order_cycle_name', with: 'Plums & Avos'
      fill_in 'order_cycle_orders_open_at', with: order_cycle_opening_time
      fill_in 'order_cycle_orders_close_at', with: order_cycle_closing_time

      # And I configure some coordinator fees
      click_button 'Add coordinator fee'
      select 'Coord fee 1', from: 'order_cycle_coordinator_fee_0_id'
      click_button 'Add coordinator fee'
      click_button 'Add coordinator fee'
      click_link 'order_cycle_coordinator_fee_2_remove'
      select 'Coord fee 2', from: 'order_cycle_coordinator_fee_1_id'

      click_button 'Save and Next'
      expect(page).to have_content 'Your order cycle has been updated.'

      # And I add a supplier and some products
      expect(page).to have_selector("table.exchanges tr.supplier")
      select 'My supplier', from: 'new_supplier_id'
      click_button 'Add supplier'
      expect(page).to have_selector("table.exchanges tr.supplier", text: "My supplier")
      page.all("table.exchanges tr.supplier td.products").each(&:click)


      expect(page).to have_selector "#order_cycle_incoming_exchange_1_variants_#{initial_variants.last.id}", visible: true
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

      click_button 'Save and Next'

      # And I add a distributor and some products
      select 'My distributor', from: 'new_distributor_id'
      click_button 'Add distributor'
      expect(page).to have_field("order_cycle_outgoing_exchange_2_pickup_time")

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

      exchange_rows = page.all("table.exchanges tbody")
      exchange_rows.each do |exchange_row|
        exchange_row.find("td.products").click
        # Wait for the products panel to be visible.
        expect(exchange_row).to have_selector "tr", count: 2
      end

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

      expect(page).to have_selector "#save-bar"
      click_button 'Save and Back to List'

      oc = OrderCycle.last
      toggle_columns "Producers", "Shops"

      expect(page).to have_input "oc#{oc.id}[name]", value: "Plums & Avos"
      expect(page).to have_input "oc#{oc.id}[orders_open_at]", value: order_cycle_opening_time
      expect(page).to have_input "oc#{oc.id}[orders_close_at]", value: order_cycle_closing_time
      expect(page).to have_content coordinator.name

      expect(page).to have_selector 'td.producers', text: 'My supplier'
      expect(page).to have_selector 'td.shops', text: 'My distributor'

      # And my coordinator fees should have been configured
      expect(oc.coordinator_fee_ids).to match_array [coordinator_fee1.id, coordinator_fee2.id]

      # And my supplier fees should have been configured
      expect(oc.exchanges.incoming.last.enterprise_fee_ids).to eq([supplier_fee2.id])

      # And my distributor fees should have been configured
      expect(oc.exchanges.outgoing.last.enterprise_fee_ids).to eq([distributor_fee2.id])

      # And my tags should have been save
      expect(oc.exchanges.outgoing.last.tag_list).to eq(['wholesale'])

      # And it should have some variants selected
      selected_initial_variants = initial_variants.take initial_variants.size - 1
      expect(oc.variants.map(&:id)).to match_array((selected_initial_variants.map(&:id) + [v1.id, v2.id]))

      # And the collection details should have been updated
      expect(oc.exchanges.where(pickup_time: 'New time 0', pickup_instructions: 'New instructions 0')).to be_present
      expect(oc.exchanges.where(pickup_time: 'New time 1', pickup_instructions: 'New instructions 1')).to be_present
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
    quick_login_as_admin
    visit edit_admin_order_cycle_path(oc)

    wait_for_edit_form_to_load_order_cycle(oc)

    # Then I should see the basic settings
    expect(page.find('#order_cycle_name').value).to eq(oc.name)
    expect(page.find('#order_cycle_orders_open_at').value).to eq(oc.orders_open_at.to_s)
    expect(page.find('#order_cycle_orders_close_at').value).to eq(oc.orders_close_at.to_s)
    expect(page).to have_content "COORDINATOR #{oc.coordinator.name}"

    click_button 'Next'

    # And I should see the suppliers
    expect(page).to have_selector 'td.supplier_name', text: oc.suppliers.first.name
    expect(page).to have_selector 'td.supplier_name', text: oc.suppliers.last.name

    expect(page).to have_field 'order_cycle_incoming_exchange_0_receival_instructions', with: 'instructions 0'
    expect(page).to have_field 'order_cycle_incoming_exchange_1_receival_instructions', with: 'instructions 1'

    # And the suppliers should have products
    page.all('table.exchanges tbody tr.supplier').each_with_index do |row, i|
      row.find('td.products').click

      products_panel = page.all('table.exchanges tr.panel-row .exchange-supplied-products').select(&:visible?).first
      expect(products_panel).to have_selector "input[name='order_cycle_incoming_exchange_#{i}_select_all_variants']"

      row.find('td.products').click
    end

    # And the suppliers should have fees
    supplier = oc.suppliers.min_by(&:name)
    expect(page).to have_select 'order_cycle_incoming_exchange_0_enterprise_fees_0_enterprise_id', selected: supplier.name
    expect(page).to have_select 'order_cycle_incoming_exchange_0_enterprise_fees_0_enterprise_fee_id', selected: supplier.enterprise_fees.first.name

    supplier = oc.suppliers.max_by(&:name)
    expect(page).to have_select 'order_cycle_incoming_exchange_1_enterprise_fees_0_enterprise_id', selected: supplier.name
    expect(page).to have_select 'order_cycle_incoming_exchange_1_enterprise_fees_0_enterprise_fee_id', selected: supplier.enterprise_fees.first.name

    click_button 'Next'

    # And I should see the distributors
    expect(page).to have_selector 'td.distributor_name', text: oc.distributors.first.name
    expect(page).to have_selector 'td.distributor_name', text: oc.distributors.last.name

    expect(page).to have_field 'order_cycle_outgoing_exchange_0_pickup_time', with: 'time 0'
    expect(page).to have_field 'order_cycle_outgoing_exchange_0_pickup_instructions', with: 'instructions 0'
    expect(page).to have_field 'order_cycle_outgoing_exchange_1_pickup_time', with: 'time 1'
    expect(page).to have_field 'order_cycle_outgoing_exchange_1_pickup_instructions', with: 'instructions 1'

    # And the distributors should have products
    page.all('table.exchanges tbody tr.distributor').each_with_index do |row, i|
      row.find('td.products').click

      products_panel = page.all('table.exchanges tr.panel-row .exchange-distributed-products').select(&:visible?).first
      expect(products_panel).to have_selector "input[name='order_cycle_outgoing_exchange_#{i}_select_all_variants']"

      row.find('td.products').click
    end

    # And the distributors should have fees
    distributor = oc.distributors.min_by(&:id)
    expect(page).to have_select 'order_cycle_outgoing_exchange_0_enterprise_fees_0_enterprise_id', selected: distributor.name
    expect(page).to have_select 'order_cycle_outgoing_exchange_0_enterprise_fees_0_enterprise_fee_id', selected: distributor.enterprise_fees.first.name

    distributor = oc.distributors.max_by(&:id)
    expect(page).to have_select 'order_cycle_outgoing_exchange_1_enterprise_fees_0_enterprise_id', selected: distributor.name
    expect(page).to have_select 'order_cycle_outgoing_exchange_1_enterprise_fees_0_enterprise_fee_id', selected: distributor.enterprise_fees.first.name
  end

  scenario "editing an order cycle with an exchange between the same enterprise" do
    c = create(:distributor_enterprise, is_primary_producer: true)

    # Given two order cycles, one with a mono-enterprise incoming exchange...
    oc_incoming = create(:simple_order_cycle, suppliers: [c], coordinator: c)

    # And the other with a mono-enterprise outgoing exchange
    oc_outgoing = create(:simple_order_cycle, coordinator: c, distributors: [c])

    # When I edit the first order cycle, the exchange should appear as incoming
    quick_login_as_admin
    visit admin_order_cycle_incoming_path(oc_incoming)
    expect(page).to have_selector 'table.exchanges tr.supplier'
    visit admin_order_cycle_outgoing_path(oc_incoming)
    expect(page).not_to have_selector 'table.exchanges tr.distributor'

    # And when I edit the second order cycle, the exchange should appear as outgoing
    visit admin_order_cycle_outgoing_path(oc_outgoing)
    expect(page).to have_selector 'table.exchanges tr.distributor'
    visit admin_order_cycle_incoming_path(oc_outgoing)
    expect(page).not_to have_selector 'table.exchanges tr.supplier'
  end

  describe "editing an order cycle with multiple pages of products", js: true do
    let(:order_cycle) { create(:order_cycle) }
    let(:supplier_enterprise) { order_cycle.exchanges.incoming.first.sender }
    let!(:new_product) { create(:product, supplier: supplier_enterprise) }

    before do
      stub_const("Api::ExchangeProductsController::DEFAULT_PER_PAGE", 1)

      quick_login_as_admin
      visit admin_order_cycle_incoming_path(order_cycle)
      expect(page).to have_content "1 / 2 selected"

      page.find("tr.supplier-#{supplier_enterprise.id} td.products").click
      expect(page).to have_selector ".exchange-product-details"

      expect(page).to have_content "1 of 2 Variants Loaded"
      expect(page).to_not have_content new_product.name
    end

    scenario "load all products" do
      page.find(".exchange-load-all-variants a").click

      expect_all_products_loaded
    end

    scenario "select all products" do
      check "order_cycle_incoming_exchange_0_select_all_variants"

      expect_all_products_loaded

      expect(page).to have_checked_field "order_cycle_incoming_exchange_0_variants_#{new_product.variants.first.id}", disabled: false
    end

    def expect_all_products_loaded
      expect(page).to have_content new_product.name.upcase
      expect(page).to have_content "2 of 2 Variants Loaded"
    end
  end

  scenario "updating many order cycle opening/closing times at once", js: true do
    # Given three order cycles
    oc1 = create(:simple_order_cycle)
    oc2 = create(:simple_order_cycle)
    oc3 = create(:simple_order_cycle,
                 orders_open_at: Time.zone.local(2040, 12, 12, 12, 12, 12),
                 orders_close_at: Time.zone.local(2041, 12, 12, 12, 12, 12))

    # When I go to the order cycles page
    quick_login_as_admin
    visit admin_order_cycles_path

    # And I fill in some new opening/closing times and save them
    within("tr.order-cycle-#{oc1.id}") do
      find("input#oc#{oc1.id}_name").set "Updated Order Cycle 1"
      find("input#oc#{oc1.id}_orders_open_at").set "2040-12-01 12:00:00"
      find("input#oc#{oc1.id}_orders_close_at").set "2040-12-01 12:00:01"
    end

    within("tr.order-cycle-#{oc2.id}") do
      find("input#oc#{oc2.id}_name").set "Updated Order Cycle 2"
      find("input#oc#{oc2.id}_orders_open_at").set "2040-12-01 12:00:02"
      find("input#oc#{oc2.id}_orders_close_at").set "2040-12-01 12:00:03"
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
      expect(find("input#oc#{oc3.id}_orders_open_at").value).to eq "2040-12-01 00:00"

      # Manually fill out time
      find("input#oc#{oc3.id}_name").set "Updated Order Cycle 3"
      find("input#oc#{oc3.id}_orders_open_at").set "2040-12-01 12:00:04"
      find("input#oc#{oc3.id}_orders_close_at").set "2040-12-01 12:00:05"
    end

    click_button 'Save Changes'

    # Then my details should have been saved
    expect(page).to have_selector "#save-bar", text: "Order cycles have been updated."
    order_cycles = OrderCycle.order("id ASC")
    expect(order_cycles.map(&:name)).to eq ["Updated Order Cycle 1", "Updated Order Cycle 2", "Updated Order Cycle 3"]
    expect(order_cycles.map { |oc| oc.orders_open_at.sec }).to eq [0, 2, 4]
    expect(order_cycles.map { |oc| oc.orders_close_at.sec }).to eq [1, 3, 5]
  end

  scenario "cloning an order cycle" do
    # Given an order cycle
    oc = create(:simple_order_cycle)

    # When I clone it
    quick_login_as_admin
    visit admin_order_cycles_path
    within "tr.order-cycle-#{oc.id}" do
      find('a.clone-order-cycle').click
    end
    expect(flash_message).to eq "Your order cycle #{oc.name} has been cloned."

    # Then I should have clone of the order cycle
    occ = OrderCycle.last
    expect(occ.name).to eq "COPY OF #{oc.name}"
  end

  describe "ensuring that hubs in order cycles have valid shipping and payment methods" do
    context "when they don't" do
      let(:hub) { create(:distributor_enterprise) }
      let!(:oc) { create(:simple_order_cycle, distributors: [hub]) }

      it "displays a warning on the dashboard" do
        login_to_admin_section
        expect(page).to have_content "The hub #{hub.name} is listed in an active order cycle, but does not have valid shipping and payment methods. Until you set these up, customers will not be able to shop at this hub."
      end

      it "displays a warning on the order cycles screen" do
        quick_login_as_admin
        visit admin_order_cycles_path
        expect(page).to have_content "The hub #{hub.name} is listed in an active order cycle, but does not have valid shipping and payment methods. Until you set these up, customers will not be able to shop at this hub."
      end
    end

    context "when they do" do
      let(:hub) { create(:distributor_enterprise, with_payment_and_shipping: true) }
      let!(:oc) { create(:simple_order_cycle, distributors: [hub]) }

      it "does not display the warning on the dashboard" do
        login_to_admin_section
        expect(page).not_to have_content "does not have valid shipping and payment methods"
      end
    end
  end

  context "as an enterprise user" do
    let!(:supplier_managed) { create(:supplier_enterprise, name: 'Managed supplier') }
    let!(:supplier_unmanaged) { create(:supplier_enterprise, name: 'Unmanaged supplier') }
    let!(:supplier_permitted) { create(:supplier_enterprise, name: 'Permitted supplier') }
    let!(:distributor_managed) { create(:distributor_enterprise, name: 'Managed distributor') }
    let!(:other_distributor_managed) { create(:distributor_enterprise, name: 'Other Managed distributor') }
    let!(:distributor_unmanaged) { create(:distributor_enterprise, name: 'Unmanaged Distributor') }
    let!(:distributor_permitted) { create(:distributor_enterprise, name: 'Permitted distributor') }
    let!(:distributor_managed_fee) { create(:enterprise_fee, enterprise: distributor_managed, name: 'Managed distributor fee') }
    let!(:shipping_method) { create(:shipping_method, distributors: [distributor_managed, distributor_unmanaged, distributor_permitted]) }
    let!(:payment_method) { create(:payment_method, distributors: [distributor_managed, distributor_unmanaged, distributor_permitted]) }
    let!(:product_managed) { create(:product, supplier: supplier_managed) }
    let!(:variant_managed) { product_managed.variants.first }
    let!(:product_permitted) { create(:product, supplier: supplier_permitted) }
    let!(:variant_permitted) { product_permitted.variants.first }
    let!(:schedule) { create(:schedule, name: 'Schedule1', order_cycles: [create(:simple_order_cycle, coordinator: distributor_managed)]) }
    let!(:schedule_of_other_managed_distributor) { create(:schedule, name: 'Other Schedule', order_cycles: [create(:simple_order_cycle, coordinator: other_distributor_managed)]) }

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
        @new_user.enterprise_roles.build(enterprise: other_distributor_managed).save

        quick_login_as @new_user
      end

      scenario "viewing a list of order cycles I am coordinating" do
        oc_user_coordinating = create(:simple_order_cycle, suppliers: [supplier_managed, supplier_unmanaged], coordinator: distributor_managed, distributors: [distributor_managed, distributor_unmanaged], name: 'Order Cycle 1' )
        oc_for_other_user = create(:simple_order_cycle, coordinator: supplier_unmanaged, name: 'Order Cycle 2' )

        visit spree.admin_dashboard_path
        click_link "Order Cycles"

        # I should see only the order cycle I am coordinating
        expect(page).to have_selector "tr.order-cycle-#{oc_user_coordinating.id}"
        expect(page).to_not have_selector "tr.order-cycle-#{oc_for_other_user.id}"

        toggle_columns "Producers", "Shops"

        # The order cycle should show all enterprises in the order cycle
        expect(page).to have_selector 'td.producers', text: supplier_managed.name
        expect(page).to have_selector 'td.shops', text: distributor_managed.name
        expect(page).to have_selector 'td.producers', text: supplier_unmanaged.name
        expect(page).to have_selector 'td.shops', text: distributor_unmanaged.name
      end

      scenario "creating a new order cycle" do
        distributor_managed.update_attribute(:enable_subscriptions, true)
        visit admin_order_cycles_path
        click_link 'New Order Cycle'

        [distributor_unmanaged.name, supplier_managed.name, supplier_unmanaged.name].each do |enterprise_name|
          expect(page).not_to have_select 'coordinator_id', with_options: [enterprise_name]
        end
        select2_select 'Managed distributor', from: 'coordinator_id'
        click_button "Continue >"

        fill_in 'order_cycle_name', with: 'My order cycle'
        fill_in 'order_cycle_orders_open_at', with: '2040-11-06 06:00:00'
        fill_in 'order_cycle_orders_close_at', with: '2040-11-13 17:00:00'
        expect(page).not_to have_select2 'schedule_ids', with_options: [schedule_of_other_managed_distributor.name]
        multi_select2_select schedule.name, from: 'schedule_ids'

        click_button 'Add coordinator fee'
        select 'Managed distributor fee', from: 'order_cycle_coordinator_fee_0_id'

        click_button 'Create'

        expect(page).to have_select 'new_supplier_id'
        expect(page).not_to have_select 'new_supplier_id', with_options: [supplier_unmanaged.name]
        select 'Managed supplier', from: 'new_supplier_id'
        click_button 'Add supplier'
        select 'Permitted supplier', from: 'new_supplier_id'
        click_button 'Add supplier'

        select_incoming_variant supplier_managed, 0, variant_managed
        select_incoming_variant supplier_permitted, 1, variant_permitted

        click_button 'Save and Next'

        expect(page).to have_select 'new_distributor_id'
        expect(page).not_to have_select 'new_distributor_id', with_options: [distributor_unmanaged.name]
        select 'Managed distributor', from: 'new_distributor_id'
        click_button 'Add distributor'
        select 'Permitted distributor', from: 'new_distributor_id'
        click_button 'Add distributor'

        fill_in 'order_cycle_outgoing_exchange_0_pickup_time', with: 'pickup time'
        fill_in 'order_cycle_outgoing_exchange_0_pickup_instructions', with: 'pickup instructions'
        fill_in 'order_cycle_outgoing_exchange_1_pickup_time', with: 'pickup time 2'
        fill_in 'order_cycle_outgoing_exchange_1_pickup_instructions', with: 'pickup instructions'

        page.find("table.exchanges tr.distributor-#{distributor_managed.id} td.tags").click
        within ".exchange-tags" do
          find(:css, "tags-input .tags input").set "wholesale\n"
        end

        click_button 'Save and Back to List'
        order_cycle = OrderCycle.find_by_name('My order cycle')
        expect(page).to have_input "oc#{order_cycle.id}[name]", value: order_cycle.name

        expect(order_cycle.suppliers).to match_array [supplier_managed, supplier_permitted]
        expect(order_cycle.coordinator).to eq(distributor_managed)
        expect(order_cycle.distributors).to match_array [distributor_managed, distributor_permitted]
        expect(order_cycle.schedules).to eq([schedule])
        exchange = order_cycle.exchanges.outgoing.to_enterprise(distributor_managed).first
        expect(exchange.tag_list).to eq(["wholesale"])
      end

      scenario "editing an order cycle" do
        oc = create(:simple_order_cycle, suppliers: [supplier_managed, supplier_permitted, supplier_unmanaged], coordinator: distributor_managed, distributors: [distributor_managed, distributor_permitted, distributor_unmanaged], name: 'Order Cycle 1' )
        distributor_managed.update_attribute(:enable_subscriptions, true)

        visit edit_admin_order_cycle_path(oc)

        expect(page).to have_field 'order_cycle_name', with: oc.name
        multi_select2_select schedule.name, from: 'schedule_ids'
        expect(page).not_to have_select2 'schedule_ids', with_options: [schedule_of_other_managed_distributor.name]

        click_button 'Save and Next'

        # When I remove all incoming exchanges
        page.find("tr.supplier-#{supplier_managed.id} a.remove-exchange").click
        page.find("tr.supplier-#{supplier_permitted.id} a.remove-exchange").click
        click_button 'Save and Next'

        # And I remove all outgoing exchanges
        page.find("tr.distributor-#{distributor_managed.id} a.remove-exchange").click
        page.find("tr.distributor-#{distributor_permitted.id} a.remove-exchange").click
        click_button 'Save and Back to List'
        expect(page).to have_input "oc#{oc.id}[name]", value: oc.name

        oc.reload
        expect(oc.suppliers).to eq([supplier_unmanaged])
        expect(oc.coordinator).to eq(distributor_managed)
        expect(oc.distributors).to eq([distributor_unmanaged])
        expect(oc.schedules).to eq([schedule])
      end

      scenario "cloning an order cycle" do
        oc = create(:simple_order_cycle, coordinator: distributor_managed)

        visit admin_order_cycles_path
        within "tr.order-cycle-#{oc.id}" do
          find('a.clone-order-cycle').click
        end
        expect(flash_message).to eq "Your order cycle #{oc.name} has been cloned."

        # Then I should have clone of the order cycle
        occ = OrderCycle.last
        expect(occ.name).to eq("COPY OF #{oc.name}")
      end
    end

    context "that is a manager of a participating producer" do
      let(:new_user) { create_enterprise_user }

      before do
        new_user.enterprise_roles.build(enterprise: supplier_managed).save
        login_to_admin_as new_user
      end

      scenario "editing an order cycle" do
        oc = create(:simple_order_cycle, suppliers: [supplier_managed, supplier_permitted, supplier_unmanaged], coordinator: distributor_managed, distributors: [distributor_managed, distributor_permitted, distributor_unmanaged], name: 'Order Cycle 1' )
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
          { distributor_managed.id.to_s => [v1.id] }
        end

        # I should only see exchanges for supplier_managed AND
        # distributor_managed and distributor_permitted (who I have given permission to) AND
        # and distributor_unmanaged (who distributes my products)
        visit admin_order_cycle_incoming_path(oc)
        expect(page).to have_selector "tr.supplier-#{supplier_managed.id}"
        expect(page).to have_selector 'tr.supplier', count: 1

        visit admin_order_cycle_outgoing_path(oc)
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

        expect(page).not_to have_selector "table.exchanges tr.distributor-#{distributor_managed.id} td.tags"

        # When I save, any exchanges that I can't manage remain
        click_button 'Save'
        expect(page).to have_content "Your order cycle has been updated."

        oc.reload
        expect(oc.suppliers).to match_array [supplier_managed, supplier_permitted, supplier_unmanaged]
        expect(oc.coordinator).to eq(distributor_managed)
        expect(oc.distributors).to match_array [distributor_managed, distributor_permitted, distributor_unmanaged]
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
        oc = create(:simple_order_cycle, suppliers: [supplier_managed, supplier_permitted, supplier_unmanaged], coordinator: distributor_managed, distributors: [my_distributor, distributor_managed, distributor_permitted, distributor_unmanaged], name: 'Order Cycle 1' )
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
          { supplier_managed.id.to_s => [v1.id] }
        end

        # I should see exchanges for my_distributor, and the incoming exchanges supplying the variants in it
        visit admin_order_cycle_outgoing_path(oc)
        expect(page).to have_selector "tr.distributor-#{my_distributor.id}"
        expect(page).to have_selector 'tr.distributor', count: 1

        visit admin_order_cycle_incoming_path(oc)
        expect(page).to have_selector "tr.supplier-#{supplier_managed.id}"
        expect(page).to have_selector 'tr.supplier', count: 1

        # Open the products list for managed_supplier's incoming exchange
        within "tr.supplier-#{supplier_managed.id}" do
          page.find("td.products").click
        end

        # I should be able to see and toggle v1
        expect(page).to have_checked_field "order_cycle_incoming_exchange_0_variants_#{v1.id}", disabled: false
        uncheck "order_cycle_incoming_exchange_0_variants_#{v1.id}"

        # I should be able to see but not toggle v2, because I don't have permission
        expect(page).to have_checked_field "order_cycle_incoming_exchange_0_variants_#{v2.id}", disabled: true

        # When I save, any exchange that I can't manage remains
        click_button 'Save and Next'
        expect(page).to have_content "Your order cycle has been updated."

        expect(page).to have_selector "table.exchanges tr.distributor-#{my_distributor.id} td.tags"

        oc.reload
        expect(oc.suppliers).to match_array [supplier_managed, supplier_permitted, supplier_unmanaged]
        expect(oc.coordinator).to eq(distributor_managed)
        expect(oc.distributors).to match_array [my_distributor, distributor_managed, distributor_permitted, distributor_unmanaged]
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
      expect(page).not_to have_selector 'th', text: 'SUPPLIERS'
      expect(page).not_to have_selector 'th', text: 'COORDINATOR'
      expect(page).not_to have_selector 'th', text: 'DISTRIBUTORS'
    end

    it "creates order cycles", js: true do
      # When I go to the new order cycle page
      visit admin_order_cycles_path
      click_link 'New Order Cycle'

      # I cannot save without the required fields
      expect(page).to have_button('Create', disabled: true)

      # The Create button is enabled once the mandatory fields are entered
      fill_in 'order_cycle_name', with: 'Plums & Avos'
      fill_in 'order_cycle_outgoing_exchange_0_pickup_time', with: 'pickup time'
      expect(page).to have_button('Create', disabled: false)

      # If I fill in the basic fields
      fill_in 'order_cycle_orders_open_at', with: '2040-10-17 06:00:00'
      fill_in 'order_cycle_orders_close_at', with: '2040-10-24 17:00:00'
      fill_in 'order_cycle_outgoing_exchange_0_pickup_instructions', with: 'pickup instructions'

      # Then my products / variants should already be selected
      expect(page).to have_checked_field "order_cycle_incoming_exchange_0_variants_#{v1.id}"
      expect(page).to have_checked_field "order_cycle_incoming_exchange_0_variants_#{v2.id}"
      expect(page).to have_checked_field "order_cycle_incoming_exchange_0_variants_#{v3.id}"

      # When I unselect a product
      uncheck "order_cycle_incoming_exchange_0_variants_#{v2.id}"

      # And I add a fee and save
      click_button 'Add coordinator fee'
      click_button 'Add coordinator fee'
      click_link 'order_cycle_coordinator_fee_1_remove'
      expect(page).to     have_select 'order_cycle_coordinator_fee_0_id'
      expect(page).not_to have_select 'order_cycle_coordinator_fee_1_id'

      select 'Coord fee', from: 'order_cycle_coordinator_fee_0_id'
      click_button 'Create'

      # Then my order cycle should have been created
      expect(page).to have_content 'Your order cycle has been created.'

      oc = OrderCycle.last

      expect(page).to have_input "oc#{oc.id}[name]", value: "Plums & Avos"
      expect(page).to have_input "oc#{oc.id}[orders_open_at]", value: Time.zone.local(2040, 10, 17, 0o6, 0o0, 0o0).strftime("%F %T %z")
      expect(page).to have_input "oc#{oc.id}[orders_close_at]", value: Time.zone.local(2040, 10, 24, 17, 0o0, 0o0).strftime("%F %T %z")

      # And it should have some variants selected
      expect(oc.exchanges.incoming.first.variants.count).to eq(2)
      expect(oc.exchanges.outgoing.first.variants.count).to eq(2)

      # And it should have the fee
      expect(oc.coordinator_fees).to eq([fee])

      # And my pickup time and instructions should have been saved
      ex = oc.exchanges.outgoing.first
      expect(ex.pickup_time).to eq('pickup time')
      expect(ex.pickup_instructions).to eq('pickup instructions')
    end

    scenario "editing an order cycle" do
      # Given an order cycle with pickup time and instructions
      fee = create(:enterprise_fee, name: 'my fee', enterprise: enterprise)
      oc = create(:simple_order_cycle, suppliers: [enterprise], coordinator: enterprise, distributors: [enterprise], variants: [v1], coordinator_fees: [fee])
      ex = oc.exchanges.outgoing.first
      ex.update_attributes! pickup_time: 'pickup time', pickup_instructions: 'pickup instructions'

      # When I edit it
      quick_login_as_admin
      visit admin_order_cycles_path
      within "tr.order-cycle-#{oc.id}" do
        find("a.edit-order-cycle").click
      end

      wait_for_edit_form_to_load_order_cycle(oc)

      # Then I should see the basic settings
      expect(page).to have_field 'order_cycle_name', with: oc.name
      expect(page).to have_field 'order_cycle_orders_open_at', with: oc.orders_open_at.to_s
      expect(page).to have_field 'order_cycle_orders_close_at', with: oc.orders_close_at.to_s
      expect(page).to have_field 'order_cycle_outgoing_exchange_0_pickup_time', with: 'pickup time'
      expect(page).to have_field 'order_cycle_outgoing_exchange_0_pickup_instructions', with: 'pickup instructions'

      # And I should see the products
      expect(page).to have_checked_field   "order_cycle_incoming_exchange_0_variants_#{v1.id}"
      expect(page).to have_unchecked_field "order_cycle_incoming_exchange_0_variants_#{v2.id}"
      expect(page).to have_unchecked_field "order_cycle_incoming_exchange_0_variants_#{v3.id}"

      # And I should see the coordinator fees
      expect(page).to have_select 'order_cycle_coordinator_fee_0_id', selected: 'my fee'
    end

    scenario "updating an order cycle" do
      # Given an order cycle with pickup time and instructions
      fee1 = create(:enterprise_fee, name: 'my fee', enterprise: enterprise)
      fee2 = create(:enterprise_fee, name: 'that fee', enterprise: enterprise)
      oc = create(:simple_order_cycle, suppliers: [enterprise], coordinator: enterprise, distributors: [enterprise], variants: [v1], coordinator_fees: [fee1])
      ex = oc.exchanges.outgoing.first
      ex.update_attributes! pickup_time: 'pickup time', pickup_instructions: 'pickup instructions'

      # When I edit it
      quick_login_as_admin
      visit edit_admin_order_cycle_path oc

      wait_for_edit_form_to_load_order_cycle(oc)

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
      expect(page).not_to have_select 'order_cycle_coordinator_fee_0_id'
      click_button 'Add coordinator fee'
      select 'that fee', from: 'order_cycle_coordinator_fee_0_id'

      # When I update, or update and close, both work
      click_button 'Save'
      expect(page).to have_content 'Your order cycle has been updated.'

      fill_in 'order_cycle_outgoing_exchange_0_pickup_instructions', with: 'yyz'
      click_button 'Save and Back to List'

      # Then my order cycle should have been updated
      expect(page).to have_content 'Your order cycle has been updated.'
      oc = OrderCycle.last

      expect(page).to have_input "oc#{oc.id}[name]", value: "Plums & Avos"
      expect(page).to have_input "oc#{oc.id}[orders_open_at]", value: Time.zone.local(2040, 10, 17, 0o6, 0o0, 0o0).strftime("%F %T %z")
      expect(page).to have_input "oc#{oc.id}[orders_close_at]", value: Time.zone.local(2040, 10, 24, 17, 0o0, 0o0).strftime("%F %T %z")

      # And it should have a variant selected
      expect(oc.exchanges.incoming.first.variants).to eq([v2])
      expect(oc.exchanges.outgoing.first.variants).to eq([v2])

      # And it should have the fee
      expect(oc.coordinator_fees).to eq([fee2])

      # And my pickup time and instructions should have been saved
      ex = oc.exchanges.outgoing.first
      expect(ex.pickup_time).to eq('xy')
      expect(ex.pickup_instructions).to eq('yyz')
    end
  end

  scenario "deleting an order cycle" do
    order_cycle = create(:simple_order_cycle, name: "Translusent Berries")
    quick_login_as_admin
    visit admin_order_cycles_path
    expect(page).to have_selector "tr.order-cycle-#{order_cycle.id}"
    accept_alert do
      first('a.delete-order-cycle').click
    end
    expect(page).to_not have_selector "tr.order-cycle-#{order_cycle.id}"
  end

  private

  def wait_for_edit_form_to_load_order_cycle(order_cycle)
    expect(page).to have_field "order_cycle_name", with: order_cycle.name
  end

  def select_incoming_variant(supplier, exchange_no, variant)
    page.find("table.exchanges tr.supplier-#{supplier.id} td.products").click
    check "order_cycle_incoming_exchange_#{exchange_no}_variants_#{variant.id}"
  end
end
