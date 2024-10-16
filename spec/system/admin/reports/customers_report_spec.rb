# frozen_string_literal: true

require "system_helper"

RSpec.describe "Customers report" do
  include AuthenticationHelper

  let(:enterprise_user) { create(:enterprise_user) }
  let(:distributor) { enterprise_user.enterprises[0] }

  it "can be rendered" do
    login_as enterprise_user
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

  it "displays filtered data by default" do
    old_order = create(
      :completed_order_with_totals, distributor:, completed_at: 4.months.ago
    )
    new_order = create(:completed_order_with_totals, distributor:)
    future_order = create(
      :completed_order_with_totals, distributor:, completed_at: 1.day.from_now
    )

    login_as enterprise_user
    visit admin_report_path(report_type: :customers)
    run_report

    rows = find("table.report__table").all("tbody tr")
    expect(rows.count).to eq 1
    expect(rows[0].all("td")[3].text).to eq new_order.email
    expect(page).not_to have_content old_order.email
    expect(page).not_to have_content future_order.email
  end
end
