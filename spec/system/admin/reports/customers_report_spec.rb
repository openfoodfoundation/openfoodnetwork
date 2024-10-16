# frozen_string_literal: true

require "system_helper"

RSpec.describe "Customers report" do
  include AuthenticationHelper

  it "can be rendered" do
    login_as_admin
    visit admin_reports_path

    within "table.index" do
      click_link "Customers"
    end
    run_report

    expect(table_headers).to eq(
      [
        [
          "First Name", "Last Name", "Billing Address", "Email", "Phone",
          "Hub", "Hub Address", "Shipping Method", "Total Number of Orders",
          "Total incl. tax ($)", "Last completed order date",
        ]
      ]
    )
  end
end
