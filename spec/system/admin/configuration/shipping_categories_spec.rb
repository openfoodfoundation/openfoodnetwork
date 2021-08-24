# frozen_string_literal: true

require 'spec_helper'

describe "Shipping Categories" do
  include AuthenticationHelper

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
