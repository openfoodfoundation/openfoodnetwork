require 'spec_helper'

feature 'Account and Billing Settings' do
  include AuthenticationWorkflow
  include WebHelper

  describe "updating" do
    let!(:admin) { create(:admin_user) }

    before do
      Spree::Config.set({
        products_require_tax_category: false,
        shipment_inc_vat: false,
        shipping_tax_rate: 0
      })
    end

    before do
      quick_login_as_admin
    end

    context "as an admin user" do
      it "loads the page" do
        visit spree.admin_path
        click_link "Configuration"
        click_link "Tax Settings"

        expect(page).to have_unchecked_field 'preferences_products_require_tax_category'
        expect(page).to have_unchecked_field 'preferences_shipment_inc_vat'
        expect(page).to have_field 'preferences_shipping_tax_rate'
      end

      it "attributes can be changed" do
        visit spree.edit_admin_tax_settings_path

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
