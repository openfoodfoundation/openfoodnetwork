# frozen_string_literal: true

require 'system_helper'

RSpec.describe '
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
      login_as_admin
      visit spree.admin_orders_path
    end

    it "deletes orders" do
      # Verify that the orders have a STATE of COMPLETE
      expect(page).to have_selector('span', text: 'COMPLETE', count: 2)

      page.find('#selectAll').trigger('click')
      page.find("span.icon-reorder", text: "Actions").click
      within ".ofn-drop-down .menu" do
        expect(page).to have_selector("span", text: "Cancel Orders")
        page.find("span", text: "Cancel Orders").click
      end

      within '.reveal-modal' do
        expect {
          find_button("Confirm").click
        }.to change { o1.reload.state }.from('complete').to('canceled')
          .and change { o2.reload.state }.from('complete').to('canceled')
      end

      # Verify that the orders have a STATE of Cancelled
      expect(page).to have_selector('span.canceled', text: 'CANCELLED', count: 2)
    end
  end
end
