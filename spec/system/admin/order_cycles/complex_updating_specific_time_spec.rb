# frozen_string_literal: true

require 'system_helper'

xdescribe '
    As an administrator
    I want to create/update complex order cycles with a specific time
' do
  include AdminHelper
  include AuthenticationHelper
  include WebHelper

  let(:order_cycle_opening_time) {
    Time.zone.local(2040, 11, 0o6, 0o6, 0o0, 0o0).strftime("%F %T %z")
  }
  let(:order_cycle_closing_time) {
    Time.zone.local(2040, 11, 13, 17, 0o0, 0o0).strftime("%F %T %z")
  }

  it "updating an order cycle" do
    # Given an order cycle with all the settings
    oc = create(:order_cycle)
    initial_variants = oc.variants.sort_by(&:id)

    # And a coordinating, supplying and distributing enterprise with some products with variants
    coordinator = oc.coordinator
    supplier = create(:supplier_enterprise, name: 'My supplier')
    distributor = create(:distributor_enterprise, name: 'My distributor',
                                                  with_payment_and_shipping: true)
    product = create(:product, supplier: supplier)
    v1 = create(:variant, product: product)
    v2 = create(:variant, product: product)

    # Relationships required for interface to work
    create(:enterprise_relationship, parent: supplier, child: coordinator,
                                     permissions_list: [:add_to_order_cycle])
    create(:enterprise_relationship, parent: distributor, child: coordinator,
                                     permissions_list: [:add_to_order_cycle])
    create(:enterprise_relationship, parent: supplier, child: distributor,
                                     permissions_list: [:add_to_order_cycle])

    # And some enterprise fees
    supplier_fee1 = create(:enterprise_fee, enterprise: supplier, name: 'Supplier fee 1')
    supplier_fee2 = create(:enterprise_fee, enterprise: supplier, name: 'Supplier fee 2')
    coordinator_fee1 = create(:enterprise_fee, enterprise: coordinator, name: 'Coord fee 1')
    coordinator_fee2 = create(:enterprise_fee, enterprise: coordinator, name: 'Coord fee 2')
    distributor_fee1 = create(:enterprise_fee, enterprise: distributor, name: 'Distributor fee 1')
    distributor_fee2 = create(:enterprise_fee, enterprise: distributor, name: 'Distributor fee 2')

    # When I go to its edit page
    login_as_admin_and_visit admin_order_cycles_path
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

    open_all_exchange_product_tabs

    expect(page).to have_selector "#order_cycle_incoming_exchange_1_variants_#{initial_variants.last.id}"
    page.find("#order_cycle_incoming_exchange_1_variants_#{initial_variants.last.id}").click # uncheck (with visible:true filter)
    check "order_cycle_incoming_exchange_2_variants_#{v1.id}"
    check "order_cycle_incoming_exchange_2_variants_#{v2.id}"

    # And I configure some supplier fees
    within("tr.supplier-#{supplier.id}") { click_button 'Add fee' }
    select 'My supplier', from: 'order_cycle_incoming_exchange_2_enterprise_fees_0_enterprise_id'
    select 'Supplier fee 1',
           from: 'order_cycle_incoming_exchange_2_enterprise_fees_0_enterprise_fee_id'
    within("tr.supplier-#{supplier.id}") { click_button 'Add fee' }
    within("tr.supplier-#{supplier.id}") { click_button 'Add fee' }
    click_link 'order_cycle_incoming_exchange_2_enterprise_fees_0_remove'
    select 'My supplier', from: 'order_cycle_incoming_exchange_2_enterprise_fees_0_enterprise_id'
    select 'Supplier fee 2',
           from: 'order_cycle_incoming_exchange_2_enterprise_fees_0_enterprise_fee_id'

    click_button 'Save and Next'
    expect(page).to have_content 'Your order cycle has been updated.'

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

    open_all_exchange_product_tabs

    uncheck "order_cycle_outgoing_exchange_2_variants_#{v1.id}"
    check "order_cycle_outgoing_exchange_2_variants_#{v2.id}"

    # And I configure some distributor fees
    within("tr.distributor-#{distributor.id}") { click_button 'Add fee' }
    select 'My distributor', from: 'order_cycle_outgoing_exchange_2_enterprise_fees_0_enterprise_id'
    select 'Distributor fee 1',
           from: 'order_cycle_outgoing_exchange_2_enterprise_fees_0_enterprise_fee_id'
    within("tr.distributor-#{distributor.id}") { click_button 'Add fee' }
    within("tr.distributor-#{distributor.id}") { click_button 'Add fee' }
    click_link 'order_cycle_outgoing_exchange_2_enterprise_fees_0_remove'
    select 'My distributor', from: 'order_cycle_outgoing_exchange_2_enterprise_fees_0_enterprise_id'
    select 'Distributor fee 2',
           from: 'order_cycle_outgoing_exchange_2_enterprise_fees_0_enterprise_fee_id'

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
    expect(oc.variants.map(&:id)).to match_array((selected_initial_variants.map(&:id) + [v1.id,
                                                                                         v2.id]))

    # And the collection details should have been updated
    expect(oc.exchanges.where(pickup_time: 'New time 0',
                              pickup_instructions: 'New instructions 0')).to be_present
    expect(oc.exchanges.where(pickup_time: 'New time 1',
                              pickup_instructions: 'New instructions 1')).to be_present
  end

  private

  def wait_for_edit_form_to_load_order_cycle(order_cycle)
    expect(page).to have_field "order_cycle_name", with: order_cycle.name
  end

  def open_all_exchange_product_tabs
    exchange_rows = page.all("table.exchanges tbody")
    exchange_rows.each do |exchange_row|
      exchange_row.find("td.products").click
      within(exchange_row) do
        # Wait for the products panel to be visible.
        expect(page).to have_selector ".exchange-products"
      end
    end
  end
end
