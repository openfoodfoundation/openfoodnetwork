# frozen_string_literal: true

require 'system_helper'

describe '
  As an Administrator
  I want to be able to delete orders in bulk
' do
  include AdminHelper
  include AuthenticationHelper
  include WebHelper

  context "deleting orders" do
    let!(:o1) {
      create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                      completed_at: Time.zone.now )
    }
    let!(:o2) {
      create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                      completed_at: Time.zone.now )
    }

    before :each do
      login_as_admin_and_visit spree.admin_orders_path
    end

    it "deletes orders" do
      # Verify that the orders have a STATE of COMPLETE
      expect(page).to have_selector('span', text: 'COMPLETE', count: 2)

      page.check('selectAll')
      page.find('.ofn-drop-down').click
      page.find('.menu').find('span', text: 'Cancel Orders').click

      within '.modal' do
        click_on "OK"
      end

      # Verify that the orders have a STATE of CANCELLED
      expect(page).to have_selector('span', text: 'CANCELLED', count: 2)
    end
  end
end
