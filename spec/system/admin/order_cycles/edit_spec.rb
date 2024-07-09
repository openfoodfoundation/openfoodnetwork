# frozen_string_literal: true

require 'system_helper'

RSpec.describe '
    As an administrator
    I want to edit a specific order cycle
' do
  include AdminHelper
  include AuthenticationHelper
  include WebHelper

  let(:oc0) {
    create(:simple_order_cycle, name: 'oc0',
                                orders_open_at: nil, orders_close_at: nil)
  }
  let(:oc1) { create(:order_cycle, name: 'oc1') }

  context 'when cycle has attached schedule(s)' do
    it "properly toggles order cycle save bar buttons to show warning modal" do
      create(:schedule, name: 'Schedule1', order_cycles: [oc0])

      # When I go to the admin order cycle edit page
      login_as_admin
      visit edit_admin_order_cycle_path(oc0)

      expect(page).to have_selector("#linked-schedule-warning-modal")
      expect(page).not_to have_selector("#modal-actions")
      expect(page).to have_selector("#form-actions")

      # change non-date range field
      fill_in 'order_cycle_name', with: "OC0 name updated"
      expect(page).to have_content('You have unsaved changes')
      click_button('Save')
      expect(page).not_to have_selector('#linked-schedule-warning-modal .reveal-modal.in')
      expect(page).to have_content('Your order cycle has been updated.')

      # change date range field value
      time = DateTime.current
      find('#order_cycle_orders_close_at').click
      select_datetime_from_datepicker Time.zone.at(time)

      # Enable savebar save buttons to open warning modal
      expect(page.find('#order_cycle_orders_close_at').value).to eq time.strftime('%Y-%m-%d %H:%M')
      expect(page).not_to have_selector("#form-actions")
      expect(page).to have_selector("#modal-actions")
      expect(page).to have_content('You have unsaved changes')
      expect(page).not_to have_selector('#linked-schedule-warning-modal .reveal-modal.in')

      # click save to open warning modal
      click_button('Save')
      expect(page).to have_selector('#linked-schedule-warning-modal .reveal-modal.in')

      # confirm to close modal and update order cycle changed fields
      click_button('Proceed anyway')
      expect(page).not_to have_selector('#linked-schedule-warning-modal .reveal-modal.in')
      expect(page.find('#order_cycle_orders_close_at').value).to eq time.strftime('%Y-%m-%d %H:%M')
    end
  end

  context 'when cycle does not have attached schedule' do
    it "does not render warning modal" do
      # When I go to the admin order cycle edit page
      login_as_admin
      visit edit_admin_order_cycle_path(oc1)

      expect(page).not_to have_selector("#linked-schedule-warning-modal")
      expect(page).not_to have_selector("#modal-actions")
      expect(page).to have_selector("#form-actions")

      # change non-date range field value
      fill_in 'order_cycle_name', with: "OC1 name updated"
      expect(page).to have_content('You have unsaved changes')

      # click save
      click_button('Save')
      expect(page).not_to have_selector('#linked-schedule-warning-modal .reveal-modal.in')
      expect(page).to have_content('Your order cycle has been updated.')

      # change date range field value
      time = DateTime.current
      find('#order_cycle_orders_close_at').click
      select_datetime_from_datepicker Time.zone.at(time)
      expect(page).to have_content('You have unsaved changes')

      click_button('Save')
      expect(page).not_to have_selector("#modal-actions")
      expect(page).to have_content('Your order cycle has been updated.')
    end
  end
end
