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
        account_invoices_monthly_cap: 50
      })
    end

    before do
      quick_login_as_admin
    end

    context "as an admin user", js: true do
      # it "loads the page" do
      #   visit spree.admin_path
      #   click_link "Configuration"
      #   click_link "Accounts & Billing"
      #
      #   expect(page).to have_select2 "settings_accounts_distributor_id"
      #   select2_select accounts_distributor.name, from: "settings_accounts_distributor_id"
      #   expect(page).to have_select "settings_default_accounts_payment_method_id"
      #   expect(page).to have_select "settings_default_accounts_shipping_method_id"
      #   expect(page).to have_link "Update User Invoices", href: start_job_admin_accounts_and_billing_settings_path(job: { name: 'update_account_invoices'})
      #   expect(page).to have_link "Finalise User Invoices", href: start_job_admin_accounts_and_billing_settings_path(job: { name: 'finalize_account_invoices'})
      # end

      it "attributes can be changed", js: true do
        visit edit_admin_business_model_configuration_path

        fill_in "settings_account_invoices_monthly_fixed", with: 10
        fill_in "settings_account_invoices_monthly_rate", with: 0.05
        fill_in "settings_account_invoices_monthly_cap", with: 30

        click_button "Update"

        expect(Spree::Config.account_invoices_monthly_fixed).to eq 10
        expect(Spree::Config.account_invoices_monthly_rate).to eq 0.05
        expect(Spree::Config.account_invoices_monthly_cap).to eq 30
      end
    end
  end
end
