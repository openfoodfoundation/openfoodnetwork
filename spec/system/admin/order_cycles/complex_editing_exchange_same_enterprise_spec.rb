# frozen_string_literal: true

<<<<<<< HEAD
require "system_helper"

describe '
=======
require 'spec_helper'

feature '
>>>>>>> 60a05d482a8d05b075b4a16241b732e51621552c
    As an administrator
    I want to manage complex order cycles
', js: true do
  include AdminHelper
  include AuthenticationHelper
  include WebHelper

<<<<<<< HEAD
  it "editing an order cycle with an exchange between the same enterprise" do
=======
  scenario "editing an order cycle with an exchange between the same enterprise" do
>>>>>>> 60a05d482a8d05b075b4a16241b732e51621552c
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
