# frozen_string_literal: true

require 'system_helper'

describe "Users & Enterprises reports" do
  include AuthenticationHelper

  before do
    login_as_admin
    visit main_app.admin_report_path(report_type: 'users_and_enterprises')
  end

  it "displays the report" do
    enterprise = create(:supplier_enterprise)

    click_button 'Go'

    expect(page.find("table.report__table thead tr").text).to have_content([
      "USER",
      "RELATIONSHIP",
      "ENTERPRISE",
      "PRODUCER?",
      "SELLS",
      "VISIBLE",
      "CONFIRMATION DATE",
      "OFN UID"
    ].join(" "))

    row_i, row_ii = page.all("table.report__table tbody tr").map(&:text)

    expect(row_i).to have_content([
      enterprise.owner.email,
      "owns",
      enterprise.name,
      "Yes",
      "none",
      "public",
      enterprise.created_at.strftime("%Y-%m-%d %H:%M"),
      enterprise.id
    ].compact.join(" "))

    expect(row_ii).to have_content([
      enterprise.owner.email,
      "manages",
      enterprise.name,
      "Yes",
      "none",
      "public",
      enterprise.created_at.strftime("%Y-%m-%d %H:%M"),
      enterprise.id
    ].compact.join(" "))
  end
end
