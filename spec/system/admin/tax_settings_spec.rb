# frozen_string_literal: true

require 'system_helper'

describe 'Account and Billing Settings' do
  include AuthenticationHelper
  include WebHelper

  describe "updating" do
    before do
      Spree::Config.set(products_require_tax_category: false)
    end

    context "as an admin user" do
      it "loads the page" do
        login_as_admin
        visit spree.edit_admin_general_settings_path
        click_link "Tax Settings"

        expect(page).to have_unchecked_field 'preferences_products_require_tax_category'
      end

      it "attributes can be changed" do
        login_as_admin
        visit spree.edit_admin_tax_settings_path

        check 'preferences_products_require_tax_category'

        click_button "Update"

        expect(Spree::Config.products_require_tax_category).to be true
      end
    end
  end
end
