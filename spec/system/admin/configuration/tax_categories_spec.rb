# frozen_string_literal: true

require 'system_helper'

describe "Tax Categories" do
  include AuthenticationHelper
  include WebHelper

  before(:each) do
    login_as_admin
    visit spree.edit_admin_general_settings_path
  end

  context "admin visiting tax categories list" do
    it "should display the existing tax categories" do
      create(:tax_category, name: "Clothing", description: "For Clothing")
      click_link "Tax Categories"
      expect(page).to have_content("Listing Tax Categories")
      within_row(1) do
        expect(find("td:nth-child(1)").text).to eq("Clothing")
        expect(find("td:nth-child(2)").text).to eq("For Clothing")
        expect(find("td:nth-child(3)").text).to eq("False")
      end
    end
  end

  context "admin creating new tax category" do
    before(:each) do
      click_link "Tax Categories"
      click_link "admin_new_tax_categories_link"
    end

    it "should be able to create new tax category" do
      expect(page).to have_content("New Tax Category")
      fill_in "tax_category_name", with: "sports goods"
      fill_in "tax_category_description", with: "sports goods desc"
      click_button "Create"
      expect(page).to have_content("successfully created!")
    end

    it "should show validation errors if there are any" do
      click_button "Create"
      expect(page).to have_content("Name can't be blank")
    end
  end

  context "admin editing a tax category" do
    it "should be able to update an existing tax category" do
      create(:tax_category)
      click_link "Tax Categories"
      within_row(1) { find(".icon-edit").click }
      fill_in "tax_category_description", with: "desc 99"
      click_button "Update"
      expect(page).to have_content("successfully updated!")
      expect(page).to have_content("desc 99")
    end
  end
end
