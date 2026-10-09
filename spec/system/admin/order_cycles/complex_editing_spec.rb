# frozen_string_literal: true

require 'system_helper'

RSpec.describe '
    As an administrator or enterprise user
    I want to edit complex order cycles
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
    login_as_admin
    visit edit_admin_order_cycle_path(oc)

    wait_for_edit_form_to_load_order_cycle(oc)

    # Then I should see the basic settings
    expect(page.find('#order_cycle_name').value).to eq(oc.name)
    expect(page.find('#order_cycle_orders_open_at').value)
      .to eq(oc.orders_open_at.strftime("%Y-%m-%d %H:%M"))
    expect(page.find('#order_cycle_orders_close_at').value)
      .to eq(oc.orders_close_at.strftime("%Y-%m-%d %H:%M"))
    expect(page).to have_content "Coordinator #{oc.coordinator.name}"

    click_button "Next"

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

      products_panel = page.all('table.exchanges tr.panel-row .exchange-supplied-products')
        .select(&:visible?).first
      expect(products_panel).to have_selector(
        "input[name='order_cycle_incoming_exchange_#{i}_select_all_variants']"
      )

      row.find('td.products').click
    end

    # And the suppliers should have fees
    supplier = oc.suppliers.min_by(&:name)
    expect(page).to have_select(
      'order_cycle_incoming_exchange_0_enterprise_fees_0_enterprise_id',
      selected: supplier.name
    )
    expect(page).to have_select(
      'order_cycle_incoming_exchange_0_enterprise_fees_0_enterprise_fee_id',
      selected: supplier.enterprise_fees.first.name
    )
    supplier = oc.suppliers.max_by(&:name)
    expect(page).to have_select(
      'order_cycle_incoming_exchange_1_enterprise_fees_0_enterprise_id',
      selected: supplier.name
    )
    expect(page).to have_select(
      'order_cycle_incoming_exchange_1_enterprise_fees_0_enterprise_fee_id',
      selected: supplier.enterprise_fees.first.name
    )

    click_button "Next"

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

      products_panel = page.all('table.exchanges tr.panel-row .exchange-distributed-products')
        .select(&:visible?).first
      expect(products_panel).to have_selector(
        "input[name='order_cycle_outgoing_exchange_#{i}_select_all_variants']"
      )

      row.find('td.products').click
    end

    # And the distributors should have fees
    distributor = oc.distributors.min_by(&:id)
    expect(page).to have_select(
      'order_cycle_outgoing_exchange_0_enterprise_fees_0_enterprise_id',
      selected: distributor.name
    )
    expect(page).to have_select(
      'order_cycle_outgoing_exchange_0_enterprise_fees_0_enterprise_fee_id',
      selected: distributor.enterprise_fees.first.name
    )
    distributor = oc.distributors.max_by(&:id)
    expect(page).to have_select(
      'order_cycle_outgoing_exchange_1_enterprise_fees_0_enterprise_id',
      selected: distributor.name
    )
    expect(page).to have_select(
      'order_cycle_outgoing_exchange_1_enterprise_fees_0_enterprise_fee_id',
      selected: distributor.enterprise_fees.first.name
    )
  end

  context "as a hub coordinating for a single distributor" do
    let(:user) { create(:user) }
    let(:hub) { create(:distributor_enterprise, name: 'My hub', with_payment_and_shipping: true) }
    let(:producer1) { create(:supplier_enterprise, name: 'Producer 1') }
    let(:producer2) { create(:supplier_enterprise, name: 'Producer 2') }
    let!(:variant1) { create(:variant, enterprise: producer1) }
    let!(:variant2) { create(:variant, enterprise: producer2) }
    let!(:oc) {
      create(:simple_order_cycle, coordinator: hub, suppliers: [producer1, producer2],
                                  distributors: [hub], variants: [variant1])
    }

    before do
      create(:enterprise_relationship, parent: producer1, child: hub,
                                       permissions_list: [:add_to_order_cycle])
      create(:enterprise_relationship, parent: producer2, child: hub,
                                       permissions_list: [:add_to_order_cycle])
      user.enterprise_roles.create!(enterprise: hub)

      # variant1 was deliberately removed from outgoing
      oc.exchanges.outgoing.first.variants.delete(variant1)

      login_as user
    end

    it "selects newly added incoming variants in outgoing" do
      visit admin_order_cycle_incoming_path(oc)
      select_incoming_variant(producer2, variant2)

      click_button 'Save and Next'
      expect(page).to have_content 'Your order cycle has been updated.'

      open_outgoing_products(hub)
      expect(page).to have_checked_field outgoing_variant_field(variant2)
      expect(page).to have_unchecked_field outgoing_variant_field(variant1)
    end

    it "selects newly added incoming variants in outgoing when saving and going back to list" do
      visit admin_order_cycle_incoming_path(oc)
      select_incoming_variant(producer2, variant2)

      click_button 'Save'
      expect(page).to have_content 'Your order cycle has been updated.'
      click_button 'Back To List'
      expect(page).to have_input "oc#{oc.id}[name]", value: oc.name

      visit admin_order_cycle_outgoing_path(oc)
      open_outgoing_products(hub)
      expect(page).to have_checked_field outgoing_variant_field(variant2)
    end
  end

  private

  def wait_for_edit_form_to_load_order_cycle(order_cycle)
    expect(page).to have_field "order_cycle_name", with: order_cycle.name
  end

  def select_incoming_variant(supplier, variant)
    expect(page).not_to have_content "Loading..."
    page.find("table.exchanges tr.supplier-#{supplier.id} td.products").click
    page.find("input[id$='_variants_#{variant.id}']").click
  end

  def open_outgoing_products(distributor)
    expect(page).not_to have_content "Loading..."
    page.find("table.exchanges tr.distributor-#{distributor.id} td.products").click
    expect(page).to have_selector ".exchange-products"
  end

  def outgoing_variant_field(variant)
    "order_cycle_outgoing_exchange_0_variants_#{variant.id}"
  end
end
