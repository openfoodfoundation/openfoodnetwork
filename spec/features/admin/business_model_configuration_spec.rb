require 'spec_helper'

feature 'Business Model Configuration' do
  include AuthenticationWorkflow
  include WebHelper

  describe "updating" do
    let!(:admin) { create(:admin_user) }

    before do
      Spree::Config.set({
        account_invoices_monthly_fixed: 5,
        account_invoices_monthly_rate: 0.02,
        account_invoices_monthly_cap: 50,
        account_invoices_tax_rate: 0.1
      })
    end

    before do
      quick_login_as_admin
    end

    context "as an admin user", js: true do
      it "loads the page" do
        visit spree.admin_path
        click_link "Configuration"
        click_link "Business Model"

        expect(page).to have_field "settings_account_invoices_monthly_fixed", with: 5.0
        expect(page).to have_field "settings_account_invoices_monthly_rate", with: 0.02
        expect(page).to have_field "settings_account_invoices_monthly_cap", with: 50.0
        expect(page).to have_field "settings_account_invoices_tax_rate", with: 0.1
      end

      it "attributes can be changed", js: true do
        visit edit_admin_business_model_configuration_path

        fill_in "settings_account_invoices_monthly_fixed", with: 10
        fill_in "settings_account_invoices_monthly_rate", with: 0.05
        fill_in "settings_account_invoices_monthly_cap", with: 30
        fill_in "settings_account_invoices_tax_rate", with: 0.15

        click_button "Update"

        expect(page).to have_content "Business Model has been successfully updated!"
        expect(Spree::Config.account_invoices_monthly_fixed).to eq 10
        expect(Spree::Config.account_invoices_monthly_rate).to eq 0.05
        expect(Spree::Config.account_invoices_monthly_cap).to eq 30
        expect(Spree::Config.account_invoices_tax_rate).to eq 0.15
      end
    end
  end
end
