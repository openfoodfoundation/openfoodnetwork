# frozen_string_literal: true

require 'system_helper'

RSpec.describe '
    As an administrator
    I want to edit a specific order cycle
' do
  include AdminHelper
  include AuthenticationHelper
  include WebHelper

  context 'when cycle has attached order(s)' do
    let(:order) { create(:order_without_full_payment) }

    it "show warning modal when datetime field values change" do
      # When I go to the admin order cycle edit page
      login_as_admin
      visit edit_admin_order_cycle_path(order.order_cycle)

      # change non-date range field
      fill_in 'order_cycle_name', with: "Order cycle name updated"
      expect(page).to have_content('You have unsaved changes')
      click_button('Save')
      expect(page).not_to have_content "Orders are linked to this order cycle"
      expect(page).to have_content('Your order cycle has been updated.')

      # change date range field value
      time = DateTime.current
      find('#order_cycle_orders_close_at').click
      select_datetime_from_datepicker Time.zone.at(time)

      expect(page.find('#order_cycle_orders_close_at').value).to eq time.strftime('%Y-%m-%d %H:%M')
      expect(page).to have_content('You have unsaved changes')

      # click save to open warning modal
      click_button('Save')
      expect(page).to have_content('You have unsaved changes')
      expect(page).to have_content "Orders are linked to this order cycle."

      # confirm to close modal and update order cycle changed fields
      click_button('Proceed anyway')
      expect(page).not_to have_content "Orders are linked to this cycle"
      expect(page).to have_content('Your order cycle has been updated.')
      expect(page.find('#order_cycle_orders_close_at').value).to eq time.strftime('%Y-%m-%d %H:%M')
    end
  end

  context 'when cycle does not have attached schedule' do
    let(:order_cycle) {
      create(:simple_order_cycle, name: 'My Order cycle',
                                  orders_open_at: nil, orders_close_at: nil)
    }

    it "does not render warning modal" do
      # When I go to the admin order cycle edit page
      login_as_admin
      visit edit_admin_order_cycle_path(order_cycle)

      # change non-date range field value
      fill_in 'order_cycle_name', with: "OC1 name updated"
      expect(page).to have_content('You have unsaved changes')

      # click save
      click_button('Save')
      expect(page.find('#order_cycle_name').value).to eq 'OC1 name updated'
      expect(page).to have_content('Your order cycle has been updated.')

      # Now change date range field value
      time = DateTime.current
      find('#order_cycle_orders_close_at').click
      select_datetime_from_datepicker Time.zone.at(time)
      expect(page).to have_content('You have unsaved changes')

      click_button('Save')
      expect(page.find('#order_cycle_orders_close_at').value).to eq time.strftime('%Y-%m-%d %H:%M')
      expect(page).to have_content('Your order cycle has been updated.')
    end
  end
end
