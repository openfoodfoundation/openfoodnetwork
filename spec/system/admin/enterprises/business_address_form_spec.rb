# frozen_string_literal: true

require "system_helper"

describe "Business Address" do
  include WebHelper
  include AuthenticationHelper

  context "as an Enterprise user" do
    let(:enterprise_user) { create(:user, enterprise_limit: 1) }
    let(:distributor) { create(:distributor_enterprise, name: "First Distributor") }

    before do
      enterprise_user.enterprise_roles.build(enterprise: distributor).save!

      login_as enterprise_user
      visit edit_admin_enterprise_path(distributor)
    end

    describe "Business Address form" do
      def go_to_business_details
        within(".side_menu") do
          click_link "Business Details"
        end
      end

      before do
        go_to_business_details
      end

      it 'adds a business address' do
        fill_in 'enterprise_business_address_attributes_company', with: 'Company'
        fill_in 'enterprise_business_address_attributes_address1', with: '35 Ballantyne St'
        fill_in 'enterprise_business_address_attributes_city', with: 'Thornbury'
        fill_in 'enterprise_business_address_attributes_zipcode', with: '3072'
        select 'France', from: 'enterprise_business_address_attributes_country_id'
        select 'Aquitaine', from: 'enterprise_business_address_attributes_state_id'
        fill_in 'enterprise_business_address_attributes_phone', with: '0123456789'

        click_button "Update"
        expect(page).to have_content("Enterprise \"First Distributor\" has been successfully updated!")

        click_link "Business Details"
        expect(page).to have_content "France"
        expect(page).to have_content "Aquitaine"
        distributor.reload
        expect(distributor.business_address).to be_present
        expect(distributor.business_address.country).to eq Spree::Country.find_by(name: 'France')
        expect(distributor.business_address.state).to eq Spree::State.find_by(name: 'Aquitaine')
      end

      it 'is missing company field' do
        fill_in 'enterprise_business_address_attributes_address1', with: '35 Ballantyne St'
        fill_in 'enterprise_business_address_attributes_city', with: 'Thornbury'
        fill_in 'enterprise_business_address_attributes_zipcode', with: '3072'
        select 'Australia', from: 'enterprise_business_address_attributes_country_id'
        select 'Victoria', from: 'enterprise_business_address_attributes_state_id'
        fill_in 'enterprise_business_address_attributes_phone', with: '0123456789'

        click_button "Update"
        expect(page).to have_content("Business address company can't be blank")
      end

      it 'is missing address field' do
        fill_in 'enterprise_business_address_attributes_company', with: 'Company'
        fill_in 'enterprise_business_address_attributes_city', with: 'Thornbury'
        fill_in 'enterprise_business_address_attributes_zipcode', with: '3072'
        select 'Australia', from: 'enterprise_business_address_attributes_country_id'
        select 'Victoria', from: 'enterprise_business_address_attributes_state_id'
        fill_in 'enterprise_business_address_attributes_phone', with: '0123456789'

        click_button "Update"
        expect(page).to have_content("Business address address1 can't be blank")
      end

      it 'is missing city field' do
        fill_in 'enterprise_business_address_attributes_company', with: 'Company'
        fill_in 'enterprise_business_address_attributes_address1', with: '35 Ballantyne St'
        fill_in 'enterprise_business_address_attributes_zipcode', with: '3072'
        select 'Australia', from: 'enterprise_business_address_attributes_country_id'
        select 'Victoria', from: 'enterprise_business_address_attributes_state_id'
        fill_in 'enterprise_business_address_attributes_phone', with: '0123456789'

        click_button "Update"
        expect(page).to have_content("Business address city can't be blank")
      end

      it 'is missing zipcode field' do
        fill_in 'enterprise_business_address_attributes_company', with: 'Company'
        fill_in 'enterprise_business_address_attributes_address1', with: '35 Ballantyne St'
        fill_in 'enterprise_business_address_attributes_city', with: 'Thornbury'
        select 'Australia', from: 'enterprise_business_address_attributes_country_id'
        select 'Victoria', from: 'enterprise_business_address_attributes_state_id'
        fill_in 'enterprise_business_address_attributes_phone', with: '0123456789'

        click_button "Update"
        expect(page).to have_content("Business address zipcode can't be blank")
      end

      it 'is missing phone field' do
        fill_in 'enterprise_business_address_attributes_company', with: 'Company'
        fill_in 'enterprise_business_address_attributes_address1', with: '35 Ballantyne St'
        fill_in 'enterprise_business_address_attributes_city', with: 'Thornbury'
        fill_in 'enterprise_business_address_attributes_zipcode', with: '3072'
        select 'Australia', from: 'enterprise_business_address_attributes_country_id'
        select 'Victoria', from: 'enterprise_business_address_attributes_state_id'

        click_button "Update"
        expect(page).to have_content("Business address phone can't be blank")
      end

      it 'destroys business address when Reset Form button is clicked' do
        fill_in 'enterprise_business_address_attributes_company', with: 'Company'
        fill_in 'enterprise_business_address_attributes_address1', with: '35 Ballantyne St'
        fill_in 'enterprise_business_address_attributes_city', with: 'Thornbury'
        fill_in 'enterprise_business_address_attributes_zipcode', with: '3072'
        select 'Australia', from: 'enterprise_business_address_attributes_country_id'
        select 'Victoria', from: 'enterprise_business_address_attributes_state_id'
        fill_in 'enterprise_business_address_attributes_phone', with: '0123456789'

        click_button "Update"

        go_to_business_details

        click_button "Reset Form"
        expect(page).to have_content("Enterprise \"First Distributor\" has been successfully updated!")
      end

      it 'clears form when all fields  are empty' do
        fill_in 'enterprise_business_address_attributes_company', with: 'Company'
        fill_in 'enterprise_business_address_attributes_address1', with: '35 Ballantyne St'
        fill_in 'enterprise_business_address_attributes_city', with: 'Thornbury'
        fill_in 'enterprise_business_address_attributes_zipcode', with: '3072'
        select 'Australia', from: 'enterprise_business_address_attributes_country_id'
        select 'Victoria', from: 'enterprise_business_address_attributes_state_id'
        fill_in 'enterprise_business_address_attributes_phone', with: '0123456789'

        click_button "Update"

        go_to_business_details

        fill_in 'enterprise_business_address_attributes_company', with: ''
        fill_in 'enterprise_business_address_attributes_address1', with: ''
        fill_in 'enterprise_business_address_attributes_city', with: ''
        fill_in 'enterprise_business_address_attributes_zipcode', with: ''
        fill_in 'enterprise_business_address_attributes_phone', with: ''

        click_button "Update"
        expect(page).to have_content("Enterprise \"First Distributor\" has been successfully updated!")
      end
    end
  end
end
