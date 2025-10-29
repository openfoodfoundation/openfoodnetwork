# frozen_string_literal: true

require 'system_helper'

RSpec.describe "Shipping Categories" do
  include AuthenticationHelper
  include WebHelper

  let(:admin_user) { create(:user) }

  context 'user visits shipping categories page' do
    it 'header is translated' do
      category = create(:shipping_category)

      login_as_admin
      visit spree.edit_admin_shipping_category_path(category)

      expect(page).to have_content "Editing Shipping Category"
    end
  end

  context 'user adds a new shipping category with temperature control' do
    it 'user sees new shipping category with temperature control' do
      login_as_admin
      visit spree.admin_shipping_categories_path
      click_link "New Shipping Category"

      fill_in "shipping_category_name", with: "freeze"
      check "shipping_category_temperature_controlled"
      click_button "Create"

      expect(page).to have_content("successfully created!")
      expect(page).to have_content("freeze")
      row = find('tr', text: 'freeze')
      within row do
        expect(page).to have_content "Yes"
      end
    end
  end

  context 'user edits an existing shipping category' do
    it 'updates the shipping category properties' do
      category = create(:shipping_category, name: "Regular", temperature_controlled: false)

      login_as_admin
      visit spree.edit_admin_shipping_category_path(category)

      fill_in "shipping_category_name", with: "Express"
      check "shipping_category_temperature_controlled"
      click_button "Update"

      expect(page).to have_content("successfully updated!")
      expect(page).to have_content("Express")
      row = find('tr', text: 'Express')
      within row do
        expect(page).to have_content "Yes"
      end
      category.reload

      expect(page).not_to have_content("Regular")
      expect(category.name).to eq("Express")
    end
  end

  context 'user deletes a shipping category' do
    it 'removes the shipping category from the list' do
      create(:shipping_category, name: "To Be Deleted")

      login_as_admin
      visit spree.admin_shipping_categories_path

      accept_confirm do
        within find('tr', text: 'To Be Deleted') do
          find('.icon-trash').click
        end
      end

      expect(page).not_to have_content("To Be Deleted")
      expect(Spree::ShippingCategory.count).to eq(0)
    end
  end
end
