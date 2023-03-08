# frozen_string_literal: true

require 'system_helper'

describe '
    As an administrator
    I want to see alert for unsaved changes on order cycle edit page
' do
  include AuthenticationHelper
  include WebHelper

  it "Alerts for unsaved changes on general settings page" do
    
    allow_any_instance_of(AdminEditOrderCycleCtrl).to receive(:onbeforeunload).and_return("onbeforeunload was called")
    oc4 = create(:simple_order_cycle)
    login_as_admin_and_visit edit_admin_order_cycle_path(oc)

    expect(page.find('#order_cycle_name').value).to eq(oc.name)
    expect(page.find('#order_cycle_orders_open_at').value)
    .to eq(oc.orders_open_at.strftime("%Y-%m-%d %H:%M"))
    expect(page.find('#order_cycle_orders_close_at').value)
    .to eq(oc.orders_close_at.strftime("%Y-%m-%d %H:%M"))
    expect(page).to have_content "COORDINATOR #{oc.coordinator.name}"

    expect(page).to have_button('Save', disabled: true)
    expect(page).to have_button('Save and Next', disabled: true)

    # First change
    fill_in 'order_cycle_name', with: 'Bonnie'
    fill_in 'order_cycle_orders_open_at', with: '2020-01-06 06:00:00 +0000'
    fill_in 'order_cycle_orders_close_at', with: '2020-01-07 06:00:00 +0000'
    expect(page).to have_content('You have unsaved changes')
    expect(page).to have_button('Save', disabled: false)
    expect(page).to have_button('Save and Next', disabled: false)
    expect(page).to have_button('Cancel', disabled: false)
    expect(page).to have_button('Next', disabled: true)

    # Trying to go to another page with unsaved changes
    click_link 'Orders'

    # expect an alert about unsaved changes
    expect(page).to have_text("onbeforeunload was called")

    # Click cancel with unsaved changes
    click_button 'Cancel'

    # expect an alert about unsaved changes
    expect(page).to have_text("onbeforeunload was called")

    # Saving first change
    click_button 'Save'
    expect(page).to have_content('Your order cycle has been updated.')
    expect(page).to have_button('Save', disabled: true)
    expect(page).to have_button('Save and Next', disabled: true)

    # Second change
    fill_in 'order_cycle_name', with: 'Clyde'
    fill_in 'order_cycle_orders_open_at', with: '2021-01-06 06:00:00 +0000'
    fill_in 'order_cycle_orders_close_at', with: '2021-01-07 06:00:00 +0000'
    expect(page).to have_content('You have unsaved changes')
    expect(page).to have_button('Save', disabled: false)
    expect(page).to have_button('Save and Next', disabled: false)
    expect(page).to have_button('Cancel', disabled: false)
    expect(page).to have_button('Next', disabled: true)

    # Trying to go to another page with unsaved changes
    click_link 'Orders'

    # expect an alert about unsaved changes
    expect(page).to have_text("onbeforeunload was called")

    # Click cancel with unsaved changes
    click_button 'Cancel'

    # expect an alert about unsaved changes
    expect(page).to have_text("onbeforeunload was called")

    # Saving Second change
    click_button 'Save'
    expect(page).to have_content('Your order cycle has been updated.')
    expect(page).to have_button('Save', disabled: true)
    expect(page).to have_button('Save and Next', disabled: true)
  end
end
