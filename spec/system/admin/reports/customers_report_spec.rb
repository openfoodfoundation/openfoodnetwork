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

    rows = find("table.report__table").all("thead tr")
    table = rows.map { |r| r.all("th").map { |c| c.text.strip } }
    expect(table.sort).to eq([
      ["First Name", "Last Name", "Billing Address", "Email", "Phone", "Hub", "Hub Address",
       "Shipping Method", "Total Number of Orders", "Total incl. tax ($)",
       "Last completed order date"]
    ].sort)
  end
end
