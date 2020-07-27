require 'spec_helper'

feature 'Account and Billing Settings' do
  include AuthenticationHelper
  include WebHelper

  describe "updating" do
    before do
      Spree::Config.set(
        products_require_tax_category: false,
        shipment_inc_vat: false,
        shipping_tax_rate: 0
      )
    end

    context "as an admin user" do
      it "loads the page" do
        login_as_admin_and_visit spree.edit_admin_general_settings_path
        click_link "Tax Settings"

        expect(page).to have_unchecked_field 'preferences_products_require_tax_category'
        expect(page).to have_unchecked_field 'preferences_shipment_inc_vat'
        expect(page).to have_field 'preferences_shipping_tax_rate'
      end

      it "attributes can be changed" do
        login_as_admin_and_visit spree.edit_admin_tax_settings_path

        check 'preferences_products_require_tax_category'
        check 'preferences_shipment_inc_vat'
        fill_in 'preferences_shipping_tax_rate', with: '0.12'

        click_button "Update"

        expect(Spree::Config.products_require_tax_category).to be true
        expect(Spree::Config.shipment_inc_vat).to be true
        expect(Spree::Config.shipping_tax_rate).to eq 0.12
      end
    end
  end
end
