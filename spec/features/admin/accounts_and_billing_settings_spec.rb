require 'spec_helper'

feature 'Account and Billing Settings' do
  include AuthenticationWorkflow

  describe "updating" do
    let!(:admin) { create(:admin_user) }
    let!(:accounts_distributor) { create(:distributor_enterprise) }

    before do
      Spree::Config.set({
        accounts_distributor_id: 0,
        collect_billing_information: false,
        create_invoices_for_enterprise_users: false
      })
    end

    before do
      quick_login_as_admin
      visit spree.admin_path
    end

    context "as an admin user" do
      it "attributes can be changed" do
        click_link "Configuration"
        click_link "Accounts & Billing"

        select accounts_distributor.name, from: "settings_accounts_distributor_id"
        check "settings_collect_billing_information"
        check "settings_create_invoices_for_enterprise_users"

        click_button "Update"

        expect(Spree::Config.accounts_distributor_id).to eq accounts_distributor.id
        expect(Spree::Config.collect_billing_information).to be true
        expect(Spree::Config.create_invoices_for_enterprise_users).to be true
      end
    end
  end
end
