# frozen_string_literal: true

require "system_helper"

RSpec.describe "Order cycle notifications" do
  include AuthenticationHelper
  include WebHelper

  let(:user) { create(:user) }
  let(:coordinator) { create(:distributor_enterprise) }
  let!(:order_cycle) { create(:simple_order_cycle, coordinator:) }

  before do
    user.enterprise_roles.build(enterprise: coordinator).save
    login_as user
  end

  it "notifies producers and returns to the order cycles list" do
    visit edit_admin_order_cycle_path(order_cycle)

    accept_confirm do
      click_link "Notify producers"
    end

    expect(page).to have_current_path admin_order_cycles_path
    expect(page).to have_selector "#listing_order_cycles"
    expect(page).to have_content "Emails to be sent to producers have been queued for sending."
  end
end
