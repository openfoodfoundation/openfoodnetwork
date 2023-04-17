# frozen_string_literal: true

require 'system_helper'

describe "Shipping Categories" do
  include AuthenticationHelper
  include WebHelper
  let(:admin_role) { Spree::Role.find_or_create_by!(name: 'admin') }
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
end
