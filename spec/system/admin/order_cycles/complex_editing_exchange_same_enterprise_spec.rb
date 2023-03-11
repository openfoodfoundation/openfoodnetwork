# frozen_string_literal: true

require 'system_helper'

describe '
    As an administrator
    I want to manage complex order cycles
' do
  include AdminHelper
  include AuthenticationHelper
  include WebHelper

  it "editing an order cycle with an exchange between the same enterprise" do
    c = create(:distributor_enterprise, is_primary_producer: true)

    # Given two order cycles, one with a mono-enterprise incoming exchange...
    oc_incoming = create(:simple_order_cycle, suppliers: [c], coordinator: c)

    # And the other with a mono-enterprise outgoing exchange
    oc_outgoing = create(:simple_order_cycle, coordinator: c, distributors: [c])

    # When I edit the first order cycle, the exchange should appear as incoming
    login_as_admin_and_visit admin_order_cycle_incoming_path(oc_incoming)
    expect(page).to have_selector 'table.exchanges tr.supplier'
    visit admin_order_cycle_outgoing_path(oc_incoming)
    expect(page).not_to have_selector 'table.exchanges tr.distributor'

    # And when I edit the second order cycle, the exchange should appear as outgoing
    visit admin_order_cycle_outgoing_path(oc_outgoing)
    expect(page).to have_selector 'table.exchanges tr.distributor'
    visit admin_order_cycle_incoming_path(oc_outgoing)
    expect(page).not_to have_selector 'table.exchanges tr.supplier'
  end
end
