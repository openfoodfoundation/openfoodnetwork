# frozen_string_literal: true

require 'system_helper'

describe "Tax Rates" do
  include AuthenticationHelper

  let!(:calculator) { create(:calculator_per_item, calculable: create(:order)) }
  let!(:tax_rate) { create(:tax_rate, name: "IVA", calculator: calculator) }
  let!(:zone) { create(:zone, name: "Ilhas") }
  let!(:tax_category) { create(:tax_category, name: "Full") }

  before do
    login_as_admin_and_visit spree.edit_admin_general_settings_path
  end

  # Regression test for Spree #535
  it "can see a tax rate in the list if the tax category has been deleted" do
    tax_rate.tax_category.update_column(:deleted_at, Time.zone.now)
    expect { click_link "Tax Rates" }.not_to raise_error
    within("table tbody td:nth-child(3)") do
      expect(page).to have_content("N/A")
    end
  end

  # Regression test for Spree #1422
  it "can create a new tax rate" do
    click_link "Tax Rates"
    click_link "New Tax Rate"
    fill_in "Rate", with: "0.05"
    click_button "Create"
    expect(page).to have_content("Tax rate has been successfully created!")
  end

  # Adds further CRUD operations: editing, deleting
  context "while editing" do
    it "fields can be filled in and dropfdowns retains changes" do
      visit spree.edit_admin_tax_rate_path(tax_rate.id)
      fill_in "Rate", with: "0.23"
      fill_in "Name", with: "GST"

      find(:id, "tax_rate_zone_id").select "Ilhas"
      find(:id, "tax_rate_tax_category_id").select "Full"
      click_button "Update"
      expect(page).to have_content('Tax rate "GST" has been successfully updated!')
      expect(page).to have_content("0.23")
    end

    # See #6554: in order to set a Tax Rate as included in the price,
    # there must be at least one Zone set the "Default Tax Zone"
    it "checkboxes can be ticked" do
      visit spree.edit_admin_tax_rate_path(tax_rate.id)
      uncheck("tax_rate[show_rate_in_label]")
      check("tax_rate[included_in_price]")
      click_button "Update"
      expect(page).to have_content("cannot be selected unless you have set a Default Tax Zone")
    end

    it "can be deleted" do
      click_link "Tax Rates"
      accept_alert do
        find(".delete-resource").click
      end
      expect(page).not_to have_content("IVA")
    end
  end
end
