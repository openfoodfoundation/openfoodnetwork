# frozen_string_literal: true

require 'system_helper'

describe '
    As an administrator
    I want to manage complex order cycles
' do
  include AdminHelper
  include AuthenticationHelper
  include WebHelper

  it "editing an order cycle" do
    # Given an order cycle with all the settings
    oc = create(:order_cycle)
    oc.suppliers.first.update_attribute :name, 'AAA'
    oc.suppliers.last.update_attribute :name, 'ZZZ'
    oc.distributors.first.update_attribute :name, 'AAAA'
    oc.distributors.last.update_attribute :name, 'ZZZZ'

    # When I edit it
    login_as_admin_and_visit edit_admin_order_cycle_path(oc)

    wait_for_edit_form_to_load_order_cycle(oc)

    # Then I should see the basic settings
    expect(page.find('#order_cycle_name').value).to eq(oc.name)
    expect(page.find('#order_cycle_orders_open_at').value).to eq(oc.orders_open_at.strftime("%Y-%m-%d %H:%M"))
    expect(page.find('#order_cycle_orders_close_at').value).to eq(oc.orders_close_at.strftime("%Y-%m-%d %H:%M"))
    expect(page).to have_content "COORDINATOR #{oc.coordinator.name}"

    click_button 'Next'

    # And I should see the suppliers
    expect(page).to have_selector 'td.supplier_name', text: oc.suppliers.first.name
    expect(page).to have_selector 'td.supplier_name', text: oc.suppliers.last.name

    expect(page).to have_field 'order_cycle_incoming_exchange_0_receival_instructions',
                               with: 'instructions 0'
    expect(page).to have_field 'order_cycle_incoming_exchange_1_receival_instructions',
                               with: 'instructions 1'

    # And the suppliers should have products
    page.all('table.exchanges tbody tr.supplier').each_with_index do |row, i|
      row.find('td.products').click

      products_panel = page.all('table.exchanges tr.panel-row .exchange-supplied-products').select(&:visible?).first
      expect(products_panel).to have_selector "input[name='order_cycle_incoming_exchange_#{i}_select_all_variants']"

      row.find('td.products').click
    end

    # And the suppliers should have fees
    supplier = oc.suppliers.min_by(&:name)
    expect(page).to have_select 'order_cycle_incoming_exchange_0_enterprise_fees_0_enterprise_id',
                                selected: supplier.name
    expect(page).to have_select 'order_cycle_incoming_exchange_0_enterprise_fees_0_enterprise_fee_id',
                                selected: supplier.enterprise_fees.first.name

    supplier = oc.suppliers.max_by(&:name)
    expect(page).to have_select 'order_cycle_incoming_exchange_1_enterprise_fees_0_enterprise_id',
                                selected: supplier.name
    expect(page).to have_select 'order_cycle_incoming_exchange_1_enterprise_fees_0_enterprise_fee_id',
                                selected: supplier.enterprise_fees.first.name

    click_button 'Next'

    # And I should see the distributors
    expect(page).to have_selector 'td.distributor_name', text: oc.distributors.first.name
    expect(page).to have_selector 'td.distributor_name', text: oc.distributors.last.name

    expect(page).to have_field 'order_cycle_outgoing_exchange_0_pickup_time', with: 'time 0'
    expect(page).to have_field 'order_cycle_outgoing_exchange_0_pickup_instructions',
                               with: 'instructions 0'
    expect(page).to have_field 'order_cycle_outgoing_exchange_1_pickup_time', with: 'time 1'
    expect(page).to have_field 'order_cycle_outgoing_exchange_1_pickup_instructions',
                               with: 'instructions 1'

    # And the distributors should have products
    page.all('table.exchanges tbody tr.distributor').each_with_index do |row, i|
      row.find('td.products').click

      products_panel = page.all('table.exchanges tr.panel-row .exchange-distributed-products').select(&:visible?).first
      expect(products_panel).to have_selector "input[name='order_cycle_outgoing_exchange_#{i}_select_all_variants']"

      row.find('td.products').click
    end

    # And the distributors should have fees
    distributor = oc.distributors.min_by(&:id)
    expect(page).to have_select 'order_cycle_outgoing_exchange_0_enterprise_fees_0_enterprise_id',
                                selected: distributor.name
    expect(page).to have_select 'order_cycle_outgoing_exchange_0_enterprise_fees_0_enterprise_fee_id',
                                selected: distributor.enterprise_fees.first.name

    distributor = oc.distributors.max_by(&:id)
    expect(page).to have_select 'order_cycle_outgoing_exchange_1_enterprise_fees_0_enterprise_id',
                                selected: distributor.name
    expect(page).to have_select 'order_cycle_outgoing_exchange_1_enterprise_fees_0_enterprise_fee_id',
                                selected: distributor.enterprise_fees.first.name
  end

  private

  def wait_for_edit_form_to_load_order_cycle(order_cycle)
    expect(page).to have_field "order_cycle_name", with: order_cycle.name
  end
end
