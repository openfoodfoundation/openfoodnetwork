# frozen_string_literal: true

require 'system_helper'

RSpec.describe '
    As an administrator
    I want to edit a specific order cycle
' do
  include AdminHelper
  include AuthenticationHelper
  include WebHelper

  let(:order_cycle_attrs) {
    { orders_open_at: "2024-03-01 08:00", orders_close_at: "2024-03-20 20:00", }
  }
  describe 'simple order cycle' do
    let(:coordinator) { create(:distributor_enterprise, sells: 'own') }
    let(:order_cycle) {
      create(:simple_order_cycle, coordinator:, **order_cycle_attrs, suppliers: [coordinator],
                                  distributors: [coordinator])
    }

    context 'with attached order(s)' do
      let!(:order) { create(:order, order_cycle: ) }

      it "shows warning modal when datetime field values change" do
        login_as_admin
        visit edit_admin_order_cycle_path(order_cycle)

        # change non-date range field
        fill_in 'order_cycle_name', with: "Order cycle name updated"
        # Set Ready for value to enable save button
        fill_in 'order_cycle_outgoing_exchange_0_pickup_time', with: 'pickup time'

        expect(page).to have_content('You have unsaved changes')
        click_button 'Save'

        expect(page).not_to have_content "Orders are linked to this order cycle"
        expect(page).to have_field 'order_cycle_name', with: "Order cycle name updated"
        expect(page).to have_content('Your order cycle has been updated.')

        select_datetime_from "#order_cycle_orders_close_at", "2024-03-30 00:00"
        expect(page).to have_content('You have unsaved changes')

        # click save to open warning modal
        click_button('Save')
        expect(page).to have_content('You have unsaved changes')
        expect(page).to have_content "Orders are linked to this order cycle."

        # confirm to close modal and update order cycle changed fields
        click_button('Proceed anyway')
        expect(page).not_to have_content "Orders are linked to this cycle"
        expect(page).to have_field 'order_cycle_orders_close_at', with: '2024-03-30 00:00'
        expect(page).to have_content('Your order cycle has been updated.')
      end

      it "it redirects user to oc list when modal cancel is clicked" do
        login_as_admin
        visit edit_admin_order_cycle_path(order_cycle)

        select_datetime_from "#order_cycle_orders_open_at", "2024-03-30 00:00"

        # click save to open warning modal
        click_button('Save')
        expect(page).to have_content('You have unsaved changes')
        expect(page).to have_content "Orders are linked to this order cycle."

        # Now cancel modal
        within('.modal-actions') do
          click_link('Cancel')
        end
        expect(page).not_to have_content('You have unsaved changes')
        expect(page).to have_current_path admin_order_cycles_path
      end
    end

    context "with no attached order" do
      it "does not show warning modal" do
        login_as_admin
        visit edit_admin_order_cycle_path(order_cycle)

        # change non-date range field value
        fill_in "order_cycle_name", with: "OC1 name updated"
        expect(page).to have_content "You have unsaved changes"

        # click save
        click_button "Save"
        expect(page).not_to have_content "You have unsaved changes"
        expect(page).to have_content "Your order cycle has been updated."
        expect(page).to have_field "order_cycle_name", with: "OC1 name updated"

        select_datetime_from "#order_cycle_orders_close_at", "2024-03-30 01:20"
        expect(page).to have_content "You have unsaved changes"

        click_button "Save"
        expect(page).not_to have_content "You have unsaved changes"
        expect(page).to have_content "Your order cycle has been updated."
        expect(page).to have_field "order_cycle_orders_close_at", with: "2024-03-30 01:20"
      end
    end
  end

  describe 'non simple order cycle' do
    let(:coordinator) { create(:supplier_enterprise, sells: 'any') }
    let(:order_cycle) { create(:simple_order_cycle, coordinator:, **order_cycle_attrs) }

    context 'with attached orders' do
      let!(:order) { create(:order, order_cycle: ) }

      it "shows warning modal when datetime field values change" do
        login_as_admin
        visit edit_admin_order_cycle_path(order_cycle)

        # change non-date range field
        fill_in 'order_cycle_name', with: "Order cycle name updated"
        expect(page).to have_content('You have unsaved changes')
        click_button 'Save'
        expect(page).not_to have_content "Orders are linked to this order cycle"
        expect(page).to have_content('Your order cycle has been updated.')
        expect(page).to have_field 'order_cycle_name', with: "Order cycle name updated"

        select_datetime_from "#order_cycle_orders_close_at", "2024-03-30 00:00"

        expect(page).to have_content('You have unsaved changes')

        # click save to open warning modal
        click_button('Save')
        expect(page).to have_content('You have unsaved changes')
        expect(page).to have_content "Orders are linked to this order cycle."

        # confirm to close modal and update order cycle changed fields
        click_button('Proceed anyway')
        expect(page).not_to have_content "Orders are linked to this cycle"
        expect(page).to have_field 'order_cycle_orders_close_at', with: '2024-03-30 00:00'
        expect(page).to have_content('Your order cycle has been updated.')
      end
    end

    context 'with no attached orders' do
      it "does not show warning modal" do
        login_as_admin
        visit edit_admin_order_cycle_path(order_cycle)

        # change non-date range field value
        fill_in 'order_cycle_name', with: "OC1 name updated"
        expect(page).to have_content('You have unsaved changes')
        sleep(2)

        # click save
        click_button('Save')
        expect(page).to have_content('Your order cycle has been updated.')
        expect(page.find('#order_cycle_name').value).to eq 'OC1 name updated'

        select_datetime_from "#order_cycle_orders_close_at", "2024-03-30 00:00"
        expect(page).to have_content('You have unsaved changes')
        sleep(2)

        click_button('Save')
        expect(page).to have_content('Your order cycle has been updated.')
        expect(page).not_to have_content "Orders are linked to this cycle"
        expect(page).to have_field 'order_cycle_orders_close_at', with: '2024-03-30 00:00'
      end
    end
  end
end
