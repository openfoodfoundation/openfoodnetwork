require 'spec_helper'

describe "Tax Rates" do
  include AuthenticationWorkflow

  let!(:calculator) { create(:calculator_per_item, calculable: create(:order)) }
  let!(:tax_rate) { create(:tax_rate, calculator: calculator) }

  before do
    quick_login_as_admin
    visit spree.admin_dashboard_path
    click_link "Configuration"
  end

  # Regression test for #535
  it "can see a tax rate in the list if the tax category has been deleted" do
    tax_rate.tax_category.update_column(:deleted_at, Time.zone.now)
    expect { click_link "Tax Rates" }.not_to raise_error
    within("table tbody td:nth-child(3)") do
      expect(page).to have_content("N/A")
    end
  end

  # Regression test for #1422
  it "can create a new tax rate" do
    click_link "Tax Rates"
    click_link "New Tax Rate"
    fill_in "Rate", with: "0.05"
    click_button "Create"
    expect(page).to have_content("Tax Rate has been successfully created!")
  end
end
