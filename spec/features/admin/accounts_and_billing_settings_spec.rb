require 'spec_helper'

feature 'Account and Billing Settings' do
  include AuthenticationWorkflow
  include WebHelper

  describe "updating" do
    let!(:admin) { create(:admin_user) }
    let!(:pm1) { create(:payment_method) }
    let!(:sm1) { create(:shipping_method) }
    let!(:accounts_distributor) { create(:distributor_enterprise, payment_methods: [pm1], shipping_methods: [sm1]) }

    before do
      Spree::Config.set({
        accounts_distributor_id: 0,
        default_accounts_payment_method_id: 0,
        default_accounts_shipping_method_id: 0,
        auto_update_invoices: false,
        auto_finalize_invoices: false
      })
    end

    before do
      quick_login_as_admin
    end

    context "as an admin user", js: true do
      it "loads the page" do
        visit spree.admin_path
        click_link "Configuration"
        click_link "Accounts & Billing"

        expect(page).to have_select2 "settings_accounts_distributor_id"
        select2_select accounts_distributor.name, from: "settings_accounts_distributor_id"
        expect(page).to have_select "settings_default_accounts_payment_method_id"
        expect(page).to have_select "settings_default_accounts_shipping_method_id"
        expect(page).to have_link "Update User Invoices", href: start_job_admin_accounts_and_billing_settings_path(job: { name: 'update_account_invoices'})
        expect(page).to have_link "Finalise User Invoices", href: start_job_admin_accounts_and_billing_settings_path(job: { name: 'finalize_account_invoices'})
      end

      it "attributes can be changed", js: true do
        visit edit_admin_accounts_and_billing_settings_path

        select2_select accounts_distributor.name, from: "settings_accounts_distributor_id"
        select pm1.name, from: "settings_default_accounts_payment_method_id"
        select sm1.name, from: "settings_default_accounts_shipping_method_id"
        check "settings_auto_update_invoices"
        check "settings_auto_finalize_invoices"

        click_button "Update"

        expect(Spree::Config.accounts_distributor_id).to eq accounts_distributor.id
        expect(Spree::Config.default_accounts_payment_method_id).to eq pm1.id
        expect(Spree::Config.default_accounts_shipping_method_id).to eq sm1.id
        expect(Spree::Config.auto_update_invoices).to be true
        expect(Spree::Config.auto_finalize_invoices).to be true
      end
    end
  end
end
