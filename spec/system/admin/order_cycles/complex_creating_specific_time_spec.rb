# frozen_string_literal: true

require 'system_helper'

describe '
    As an administrator
    I want to create/update complex order cycles with a specific time
', js: true do
  include AdminHelper
  include AuthenticationHelper
  include WebHelper

  let(:order_cycle_opening_time) { 1.day.from_now(Time.zone.now) }
  let(:order_cycle_closing_time) { 2.days.from_now(Time.zone.now) }

  it "creating an order cycle with full interface", js: true do
    # Given coordinating, supplying and distributing enterprises with some products with variants
    coordinator = create(:distributor_enterprise, name: 'My coordinator')
    supplier = create(:supplier_enterprise, name: 'My supplier')
    product = create(:product, supplier: supplier)
    v1 = create(:variant, product: product)
    v2 = create(:variant, product: product)
    distributor = create(:distributor_enterprise, name: 'My distributor',
                                                  with_payment_and_shipping: true)

    # Relationships required for interface to work
    create(:enterprise_relationship, parent: supplier, child: coordinator,
                                     permissions_list: [:add_to_order_cycle])
    create(:enterprise_relationship, parent: distributor, child: coordinator,
                                     permissions_list: [:add_to_order_cycle])
    create(:enterprise_relationship, parent: supplier, child: distributor,
                                     permissions_list: [:add_to_order_cycle])

    # And some enterprise fees
    supplier_fee = create(:enterprise_fee, enterprise: supplier, name: 'Supplier fee')
    coordinator_fee = create(:enterprise_fee, enterprise: coordinator, name: 'Coord fee')
    distributor_fee = create(:enterprise_fee, enterprise: distributor, name: 'Distributor fee')

    # When I go to the new order cycle page
    login_as_admin_and_visit admin_order_cycles_path
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
    find('#order_cycle_orders_open_at').click
    # select date
    select_date_from_datepicker Time.zone.at(order_cycle_opening_time)
    # select time
    within(".flatpickr-calendar.open .flatpickr-time") do
      find('.flatpickr-hour').set('%02d' % order_cycle_opening_time.hour)
      find('.flatpickr-minute').set('%02d' % order_cycle_opening_time.min)
    end
    # hide the datetimepicker
    find("body").send_keys(:escape)

    find('#order_cycle_orders_close_at').click
    # select date
    select_date_from_datepicker Time.zone.at(order_cycle_closing_time)
    # select time
    within(".flatpickr-calendar.open .flatpickr-time") do
      find('.flatpickr-hour').set('%02d' % order_cycle_closing_time.hour)
      find('.flatpickr-minute').set('%02d' % order_cycle_closing_time.min)
    end
    # hide the datetimepicker
    find("body").send_keys(:escape)

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
    select 'My supplier', from: 'order_cycle_incoming_exchange_0_enterprise_fees_0_enterprise_id'
    select 'Supplier fee',
           from: 'order_cycle_incoming_exchange_0_enterprise_fees_0_enterprise_fee_id'

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
    select 'My distributor',
           from: 'order_cycle_outgoing_exchange_0_enterprise_fees_0_enterprise_id'
    select 'Distributor fee',
           from: 'order_cycle_outgoing_exchange_0_enterprise_fees_0_enterprise_fee_id'

    click_button 'Save and Back to List'

    oc = OrderCycle.last
    toggle_columns "Producers", "Shops"

    expect(page).to have_input "oc#{oc.id}[name]", value: "Plums & Avos"
    expect(page).to have_input "oc#{oc.id}[orders_open_at]",
                               value: Time.zone.at(order_cycle_opening_time), visible: false
    expect(page).to have_input "oc#{oc.id}[orders_close_at]",
                               value: Time.zone.at(order_cycle_closing_time), visible: false
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
end
