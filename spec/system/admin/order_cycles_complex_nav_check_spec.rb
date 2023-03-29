# frozen_string_literal: true

require 'system_helper'

describe '
    As an administrator
    I want to be alerted when I navigate away from a dirty order cycle form
' do
  include AuthenticationHelper

  it "alert when navigating away from dirty form" do
    # Given a 'complex' order cycle form
    oc = create(:order_cycle)

    # When I edit the form
    login_as_admin
    visit edit_admin_order_cycle_path(oc)

    wait_for_edit_form_to_load_order_cycle(oc)

    expect(page).to have_selector '.wizard-progress .current a', text: '1. GENERAL SETTINGS'
    expect(page.find('#order_cycle_name').value).to eq(oc.name)
    expect(page).to have_button("Save", disabled: true)
    fill_in 'order_cycle_name', with: 'Plums & Avos'

    # Then the form is dirty and an alert warns about navigating away from the form
    expect(page).to have_button("Save", disabled: false)
    expect(page).to have_selector '.wizard-progress a', text: '2. INCOMING PRODUCTS'
    accept_alert do
      click_link '2. Incoming Products'
    end
  end

  private

  def wait_for_edit_form_to_load_order_cycle(order_cycle)
    expect(page).to have_field "order_cycle_name", with: order_cycle.name
  end
end
