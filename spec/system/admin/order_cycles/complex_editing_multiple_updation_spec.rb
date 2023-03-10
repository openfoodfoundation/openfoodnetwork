# frozen_string_literal: true

require 'system_helper'

describe '
    As an administrator
    I want to see alert for unsaved changes on order cycle edit page
' do
  include AuthenticationHelper
  include WebHelper

  before do
    Capybara.current_driver = :selenium_chrome_headless
    Capybara.javascript_driver = :selenium_chrome_headless
    Capybara.default_max_wait_time = 10
  end

  after do
    Capybara.use_default_driver
  end

  it "Alerts for unsaved changes on general settings (/edit) page" do
    oc = create(:order_cycle)
    login_as_admin_and_visit edit_admin_order_cycle_path(oc)

    # Wait for the page to finish loading
    sleep 3

    # Expect correct values
    expect(page.find('#order_cycle_name').value).to eq(oc.name)
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
    expect(page.driver.browser.switch_to.alert.text)

    # Dismiss the alert
    page.driver.browser.switch_to.alert.dismiss

    # Click cancel with unsaved changes
    click_button 'Cancel'

    # expect an alert about unsaved changes
    expect(page.driver.browser.switch_to.alert.text)

    # Dismiss the alert
    page.driver.browser.switch_to.alert.dismiss

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
    expect(page.driver.browser.switch_to.alert.text)

    # Dismiss the alert
    page.driver.browser.switch_to.alert.dismiss

    # Click cancel with unsaved changes
    click_button 'Cancel'

    # expect an alert about unsaved changes
    expect(page.driver.browser.switch_to.alert.text)

    # Dismiss the alert
    page.driver.browser.switch_to.alert.dismiss

    # Saving Second change
    click_button 'Save'
    expect(page).to have_content('Your order cycle has been updated.')
    expect(page).to have_button('Save', disabled: true)
    expect(page).to have_button('Save and Next', disabled: true)

    # Can leave without alert if no changes have been made
    click_link 'Orders'

    # Made it to orders page
    expect(page).to have_content 'Listing Orders'
  end

  it "Alerts for unsaved changes on /incoming step" do
    oc = create(:order_cycle)
    oc.suppliers.first.update_attribute :name, 'farmer'
    login_as_admin_and_visit edit_admin_order_cycle_path(oc)

    # Go to incoming step
    click_button 'Next'

    # Wait for the page to finish loading
    sleep 3

    # Expect details
    expect(page).to have_selector 'td.supplier_name', text: oc.suppliers.first.name
    expect(page).to have_button('Save', disabled: true)
    expect(page).to have_button('Save and Next', disabled: true)

    # First change
    fill_in 'order_cycle_incoming_exchange_0_receival_instructions', with: 'its cheese'
    expect(page).to have_content('You have unsaved changes')
    expect(page).to have_button('Save', disabled: false)
    expect(page).to have_button('Save and Next', disabled: false)
    expect(page).to have_button('Cancel', disabled: false)
    expect(page).to have_button('Next', disabled: true)

    # Trying to go to another page with unsaved changes
    click_link 'Orders'

    # expect an alert about unsaved changes
    expect(page.driver.browser.switch_to.alert.text)

    # Dismiss the alert
    page.driver.browser.switch_to.alert.dismiss

    # Click cancel with unsaved changes
    click_button 'Cancel'

    # expect an alert about unsaved changes
    expect(page.driver.browser.switch_to.alert.text)

    # Dismiss the alert
    page.driver.browser.switch_to.alert.dismiss

    # Saving first change
    click_button 'Save'
    expect(page).to have_content('Your order cycle has been updated.')
    expect(page).to have_button('Save', disabled: true)
    expect(page).to have_button('Save and Next', disabled: true)

    # Second change
    fill_in 'order_cycle_incoming_exchange_0_receival_instructions', with: 'the blue kind'
    expect(page).to have_content('You have unsaved changes')
    expect(page).to have_button('Save', disabled: false)
    expect(page).to have_button('Save and Next', disabled: false)
    expect(page).to have_button('Cancel', disabled: false)
    expect(page).to have_button('Next', disabled: true)

    # Trying to go to another page with unsaved changes
    click_link 'Orders'

    # expect an alert about unsaved changes
    expect(page.driver.browser.switch_to.alert.text)

    # Dismiss the alert
    page.driver.browser.switch_to.alert.dismiss

    # Click cancel with unsaved changes
    click_button 'Cancel'

    # expect an alert about unsaved changes
    expect(page.driver.browser.switch_to.alert.text)

    # Dismiss the alert
    page.driver.browser.switch_to.alert.dismiss

    # Saving Second change
    click_button 'Save'
    expect(page).to have_content('Your order cycle has been updated.')
    expect(page).to have_button('Save', disabled: true)
    expect(page).to have_button('Save and Next', disabled: true)

    # Can leave without alert if no changes have been made
    click_link 'Orders'

    # Made it to orders page
    expect(page).to have_content 'Listing Orders'
  end

  it "Alerts for unsaved changes on /outgoing step" do
    oc = create(:order_cycle)
    oc.distributors.first.update_attribute :name, 'store'
    login_as_admin_and_visit edit_admin_order_cycle_path(oc)

    # Go to incoming step
    click_button 'Next'

    # Go to outgoing step
    click_button 'Next'

    # Wait for the page to finish loading
    sleep 3

    # Expect details
    expect(page).to have_selector 'td.distributor_name', text: oc.distributors.first.name
    expect(page).to have_field 'order_cycle_outgoing_exchange_0_pickup_instructions',
                               with: 'instructions 1'

    # First change
    fill_in 'order_cycle_outgoing_exchange_0_pickup_instructions', with: 'lift with legs'
    expect(page).to have_content('You have unsaved changes')
    expect(page).to have_button('Save', disabled: false)
    expect(page).to have_button('Save and Next', disabled: false)
    expect(page).to have_button('Cancel', disabled: false)
    expect(page).to have_button('Next', disabled: true)

    # Trying to go to another page with unsaved changes
    click_link 'Orders'

    # expect an alert about unsaved changes
    expect(page.driver.browser.switch_to.alert.text)

    # Dismiss the alert
    page.driver.browser.switch_to.alert.dismiss

    # Click cancel with unsaved changes
    click_button 'Cancel'

    # expect an alert about unsaved changes
    expect(page.driver.browser.switch_to.alert.text)

    # Dismiss the alert
    page.driver.browser.switch_to.alert.dismiss

    # Saving first change
    click_button 'Save'
    expect(page).to have_content('Your order cycle has been updated.')
    expect(page).to have_button('Save', disabled: true)
    expect(page).to have_button('Save and Next', disabled: true)

    # Second change
    fill_in 'order_cycle_outgoing_exchange_0_pickup_instructions', with: 'baby got back'
    expect(page).to have_content('You have unsaved changes')
    expect(page).to have_button('Save', disabled: false)
    expect(page).to have_button('Save and Next', disabled: false)
    expect(page).to have_button('Cancel', disabled: false)
    expect(page).to have_button('Next', disabled: true)

    # Trying to go to another page with unsaved changes
    click_link 'Orders'

    # expect an alert about unsaved changes
    expect(page.driver.browser.switch_to.alert.text)

    # Dismiss the alert
    page.driver.browser.switch_to.alert.dismiss

    # Click cancel with unsaved changes
    click_button 'Cancel'

    # expect an alert about unsaved changes
    expect(page.driver.browser.switch_to.alert.text)

    # Dismiss the alert
    page.driver.browser.switch_to.alert.dismiss

    # Saving Second change
    click_button 'Save'
    expect(page).to have_content('Your order cycle has been updated.')
    expect(page).to have_button('Save', disabled: true)
    expect(page).to have_button('Save and Next', disabled: true)

    # Can leave without alert if no changes have been made
    click_link 'Orders'

    # Made it to orders page
    expect(page).to have_content 'Listing Orders'
  end
end
