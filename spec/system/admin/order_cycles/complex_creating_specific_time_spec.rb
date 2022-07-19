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

  # Given coordinating, supplying and distributing enterprises with some products with variants
  let!(:coordinator) { create(:distributor_enterprise, name: 'My coordinator') }
  let!(:supplier) { create(:supplier_enterprise, name: 'My supplier') }
  let!(:product) { create(:product, supplier: supplier) }
  let!(:v1) { create(:variant, product: product) }
  let!(:v2) { create(:variant, product: product) }
  let!(:distributor) {
    create(:distributor_enterprise, name: 'My distributor', with_payment_and_shipping: true)
  }
  let!(:shipping_method_i) { distributor.shipping_methods.first }
  let!(:shipping_method_ii) { create(:shipping_method, distributors: [distributor]) }

  # And some enterprise fees
  let!(:supplier_fee) { create(:enterprise_fee, enterprise: supplier, name: 'Supplier fee') }
  let!(:coordinator_fee) { create(:enterprise_fee, enterprise: coordinator, name: 'Coord fee') }
  let!(:distributor_fee) { create(:enterprise_fee, enterprise: distributor, name: 'Distributor fee') }

  before do
    # Relationships required for interface to work
    create(:enterprise_relationship, parent: supplier, child: coordinator,
                                     permissions_list: [:add_to_order_cycle])
    create(:enterprise_relationship, parent: distributor, child: coordinator,
                                     permissions_list: [:add_to_order_cycle])
    create(:enterprise_relationship, parent: supplier, child: distributor,
                                     permissions_list: [:add_to_order_cycle])

    shipping_method_i.update!(name: "Pickup - always available")
    shipping_method_ii.update!(name: "Delivery - sometimes available")
  end

  it "creating an order cycle with full interface", js: true do
    ## CREATE
    login_as_admin_and_visit admin_order_cycles_path
    click_link 'New Order Cycle'

    # Select a coordinator since there are two available
    select2_select 'My coordinator', from: 'coordinator_id'
    click_button "Continue >"

    fill_in_order_cycle_name
    select_opening_and_closing_times

    click_button 'Add coordinator fee'
    select 'Coord fee', from: 'order_cycle_coordinator_fee_0_id'

    click_button 'Create'
    expect(page).to have_content 'Your order cycle has been created.'

    ## UPDATE
    add_supplier_with_fees
    add_distributor_with_fees
    select_shipping_methods

    expect_all_data_saved
  end

  def fill_in_order_cycle_name
    # I cannot save before filling in the required fields
    expect(page).to have_button("Create", disabled: true)

    # The Create button is enabled once Name is entered
    fill_in 'order_cycle_name', with: "Plums & Avos"
    expect(page).to have_button("Create", disabled: false)
  end

  def select_opening_and_closing_times
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
  end

  def add_supplier_with_fees
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
  end

  def add_distributor_with_fees
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

    click_button 'Save and Next'
  end

  def select_shipping_methods
    expect(page).to have_checked_field "Select all"

    expect(page).to have_checked_field "Pickup - always available"
    expect(page).to have_checked_field "Delivery - sometimes available"

    uncheck "Delivery - sometimes available"

    expect(page).to have_unchecked_field "Select all"

    click_button 'Save and Back to List'
  end

  def expect_all_data_saved
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

    # And the shipping method should be attached
    expect(oc.shipping_methods.map(&:name)).to eq(["Pickup - always available"])
  end
end
