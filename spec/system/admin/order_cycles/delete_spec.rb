# frozen_string_literal: true

require "system_helper"

RSpec.describe "Order cycle deletion" do
  include AdminHelper
  include AuthenticationHelper
  include WebHelper

  let!(:order_cycle_to_keep) { create(:simple_order_cycle, name: "Keep me") }
  let!(:order_cycle_to_delete) { create(:simple_order_cycle, name: "Delete me") }

  it "deletes an order cycle and reloads the list" do
    login_as_admin
    visit admin_order_cycles_path

    expect(page).to have_selector "tr.order-cycle-#{order_cycle_to_delete.id}"

    within "tr.order-cycle-#{order_cycle_to_delete.id}" do
      accept_confirm do
        find("a.delete-order-cycle").click
      end
    end

    expect(page).to have_content "Successfully Removed"
    expect(page).to have_selector "tr.order-cycle-#{order_cycle_to_keep.id}"
    expect(page).not_to have_selector "tr.order-cycle-#{order_cycle_to_delete.id}"
  end
end
