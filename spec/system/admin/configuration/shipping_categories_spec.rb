# frozen_string_literal: true

require 'system_helper'

describe "Shipping Categories" do
  include AuthenticationHelper
  include WebHelper
  let(:admin_role) { Spree::Role.find_or_create_by!(name: 'admin') }
  let(:admin_user) { create(:user) }

  context 'user visits shipping categories page' do
    it 'header is translated' do
      login_as_admin_and_visit spree.admin_shipping_categories_path(locale: 'es')
      expect(get_i18n_locale).to eq 'es'

      expect(get_i18n_translation('shipping_categories')).to eq 'Categorías de envío'
      click_link "Nueva categoría de envío"

      fill_in "shipping_category_name", with: "freeze"
      check "shipping_category_temperature_controlled"
      click_button "Crear"

      expect(page).to have_content("freeze")
      row = find('tr', text: 'freeze')
      within row do
        find('a', class: 'icon-edit').click
      end
      expect(page).to have_content "Edición de la categoría de envío"
    end
  end

  context 'user adds a new shipping category with temperature control' do
    it 'user sees new shipping category with temperature control' do
      login_as_admin_and_visit spree.admin_shipping_categories_path
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
