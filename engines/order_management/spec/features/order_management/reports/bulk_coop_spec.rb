# frozen_string_literal: true

require "spec_helper"

feature "bulk coop" do
  include AuthenticationHelper
  include WebHelper

  scenario "generating Bulk Co-op Supplier Report" do
    puts "enginefoobar"
    login_as_admin_and_visit new_order_management_reports_bulk_coop_path
    select "Bulk Co-op Supplier Report", from: "report_report_type"
    click_button 'Generate Report'

    expect(page).to have_table_row [
      "Supplier",
      "Product",
      "Bulk Unit Size",
      "Variant",
      "Variant Value",
      "Variant Unit",
      "Weight",
      "Sum Total",
      "Units Required",
      "Unallocated",
      "Max Quantity Excess"
    ]
  end

  scenario "generating Bulk Co-op Allocation report" do
    login_as_admin_and_visit new_order_management_reports_bulk_coop_path
    select "Bulk Co-op Allocation", from: "report_report_type"
    click_button 'Generate Report'

    expect(page).to have_table_row [
      "Customer",
      "Product",
      "Bulk Unit Size",
      "Variant",
      "Variant Value",
      "Variant Unit",
      "Weight",
      "Sum Total",
      "Total available",
      "Unallocated",
      "Max Quantity Excess"
    ]
  end

  scenario "generating Bulk Co-op Packing Sheets report" do
    login_as_admin_and_visit new_order_management_reports_bulk_coop_path
    select "Bulk Co-op Packing Sheets", from: "report_report_type"
    click_button 'Generate Report'

    expect(page).to have_table_row [
      "Customer",
      "Product",
      "Variant",
      "Sum Total"
    ]
  end

  scenario "generating Bulk Co-op Customer Payments report" do
    login_as_admin_and_visit new_order_management_reports_bulk_coop_path
    select "Bulk Co-op Customer Payments", from: "report_report_type"
    click_button 'Generate Report'

    expect(page).to have_table_row [
      "Customer",
      "Date of Order",
      "Total Cost",
      "Amount Owing",
      "Amount Paid"
    ]
  end
end
