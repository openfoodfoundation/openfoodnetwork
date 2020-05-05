require 'spec_helper'

feature '
    As an administrator
    I want to manage complex order cycles
', js: true do
  include AdminHelper
  include AuthenticationWorkflow
  include WebHelper

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

  private

  def wait_for_edit_form_to_load_order_cycle(order_cycle)
    expect(page).to have_field "order_cycle_name", with: order_cycle.name
  end

  def select_incoming_variant(supplier, exchange_no, variant)
    page.find("table.exchanges tr.supplier-#{supplier.id} td.products").click
    check "order_cycle_incoming_exchange_#{exchange_no}_variants_#{variant.id}"
  end
end