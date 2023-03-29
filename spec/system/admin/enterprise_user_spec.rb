# frozen_string_literal: true

require "system_helper"

describe '
    As a Super User
    I want to setup users to manage an enterprise
' do
  include WebHelper
  include AuthenticationHelper

  let!(:user) { create(:user) }
  let!(:supplier1) { create(:supplier_enterprise, name: 'Supplier 1') }
  let!(:supplier2) { create(:supplier_enterprise, name: 'Supplier 2') }
  let(:supplier_profile) { create(:supplier_enterprise, name: 'Supplier profile', sells: 'none') }
  let!(:distributor1) { create(:distributor_enterprise, name: 'Distributor 3') }
  let!(:distributor2) { create(:distributor_enterprise, name: 'Distributor 4') }
  let(:distributor_profile) {
    create(:distributor_enterprise, name: 'Distributor profile', sells: 'none')
  }

  describe "creating an enterprise user" do
    context "with a limitted number of owned enterprises" do
      it "setting the enterprise ownership limit" do
        expect(user.enterprise_limit).to eq 5
        login_as_admin
        visit spree.admin_users_path
        click_link user.email

        fill_in "user_enterprise_limit", with: 2

        click_button 'Update'
        user.reload
        expect(user.enterprise_limit).to eq 2
      end
    end
  end

  describe "system management lockdown" do
    before do
      user.enterprise_roles.create!(enterprise: supplier1)
      login_as user
    end

    it "should not be able to see system configuration" do
      visit spree.edit_admin_general_settings_path
      expect(page).to have_content 'Unauthorized'
    end

    it "should not be able to see user management" do
      visit spree.admin_users_path
      expect(page).to have_content 'Unauthorized'
    end
  end
end
