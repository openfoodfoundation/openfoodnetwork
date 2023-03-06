# frozen_string_literal: true

require 'system_helper'

describe 'shipping methods' do
  include WebHelper
  include AuthenticationHelper

  before :each do
    @shipping_method = create(:shipping_method)
  end

  context "as a site admin" do
    before(:each) do
      login_as_admin
    end

    it "creating a shipping method owned by some distributors" do
      # Given some distributors
      distributor1 = create(:distributor_enterprise, name: 'Alice Farm Hub')
      distributor2 = create(:distributor_enterprise, name: 'Bob Farm Shop')

      # Shows appropriate fields when logged in as admin
      visit spree.new_admin_shipping_method_path
      expect(page).to have_field 'shipping_method_name'
      expect(page).to have_field 'shipping_method_description'
      expect(page).to have_select 'shipping_method_display_on'
      expect(page).to have_css 'div#shipping_method_zones_field'
      expect(page).to have_field 'shipping_method_require_ship_address_true', checked: true

      # When I create a shipping method and set the distributors
      fill_in 'shipping_method_name', with: 'Carrier Pidgeon'
      check "shipping_method_distributor_ids_#{distributor1.id}"
      check "shipping_method_distributor_ids_#{distributor2.id}"
      check "shipping_method_shipping_categories_"
      click_button 'Create'

      expect(page).to have_no_button 'Create'

      # Then the shipping method should have its distributor set
      expect(flash_message).to include "Carrier Pidgeon", "successfully created!"

      sm = Spree::ShippingMethod.last
      expect(sm.name).to eq('Carrier Pidgeon')
      expect(sm.distributors).to match_array [distributor1, distributor2]
    end

    it "deleting a shipping method" do
      visit spree.admin_shipping_methods_path
        
      accept_alert 'Are you sure?' do
        page.find('a.delete-resource').click
      end
      expect(page).not_to have_content(@shipping_method)
      expect(Spree::ShippingMethod.where(id: @shipping_method.id)).to be_empty
    end

    it "checking a single distributor is checked by default" do
      first_distributor = Enterprise.first
      visit spree.new_admin_shipping_method_path
      expect(page).to have_field "shipping_method_distributor_ids_#{first_distributor.id}",
                                 checked: true
    end

    it "checking more than a distributor displays no default choice" do
      distributor1 = create(:distributor_enterprise, name: 'Alice Farm Shop')
      distributor2 = create(:distributor_enterprise, name: 'Bob Farm Hub')
      visit spree.new_admin_shipping_method_path
      expect(page).to have_field "shipping_method_distributor_ids_#{distributor1.id}",
                                 checked: false
      expect(page).to have_field "shipping_method_distributor_ids_#{distributor2.id}",
                                 checked: false
    end

    it "handle when updating calculator type for Weight to Flat Rate" do
      visit spree.edit_admin_shipping_method_path(@shipping_method)

      select2_select 'Weight (per kg or lb)', from: 'calc_type'
      click_button 'Update'

      select2_select 'Flat Rate (per item)', from: 'calc_type'
      click_button 'Update'

      expect(@shipping_method.reload.calculator_type).to eq("Calculator::PerItem")
    end

    it "handle when updating calculator type to 'None'" do
      visit spree.edit_admin_shipping_method_path(@shipping_method)

      select2_select 'None', from: 'calc_type'
      click_button 'Update'
      
      expect(@shipping_method.reload.calculator_type).to eq "Calculator::None"
    end
  end

  context "as an enterprise user" do
    let(:enterprise_user) { create(:user) }
    let(:distributor1) { create(:distributor_enterprise, name: 'First Distributor') }
    let(:distributor2) { create(:distributor_enterprise, name: 'Second Distributor') }
    let(:distributor3) { create(:distributor_enterprise, name: 'Third Distributor') }
    let(:shipping_method1) { create(:shipping_method, name: 'One', distributors: [distributor1]) }
    let(:shipping_method2) {
      create(:shipping_method, name: 'Two', distributors: [distributor1, distributor2])
    }
    let(:sm3) { create(:shipping_method, name: 'Three', distributors: [distributor3]) }
    let(:shipping_category) { create(:shipping_category) }

    before(:each) do
      enterprise_user.enterprise_roles.build(enterprise: distributor1).save
      enterprise_user.enterprise_roles.build(enterprise: distributor2).save
      login_as enterprise_user
    end

    it "creating a shipping method", retry: 3 do
      visit admin_enterprises_path
      within("#e_#{distributor1.id}") { click_link 'Settings' }
      within(".side_menu") do
        click_link "Shipping Methods"
      end
      click_link 'Create One Now'

      # Show the correct fields
      expect(page).to have_field 'shipping_method_name'
      expect(page).to have_field 'shipping_method_description'
      expect(page).to have_select 'shipping_method_display_on'
      expect(page).to have_css 'div#shipping_method_zones_field'
      expect(page).to have_field 'shipping_method_require_ship_address_true', checked: true

      # Auto-check default shipping category
      expect(page).to have_field shipping_category.name, checked: true

      fill_in 'shipping_method_name', with: 'Teleport'

      check "shipping_method_distributor_ids_#{distributor1.id}"
      find(:css, "tags-input .tags input").set "local\n"
      within(".tags .tag-list") do
        expect(page).to have_css '.tag-item', text: "local"
      end
      click_button "Create"

      within ".flash-container" do
        expect(page).to have_content 'Shipping Method "Teleport" has been successfully created!'
      end
      expect(page).to have_content "Editing Shipping Method"

      expect(first('tags-input .tag-list ti-tag-item')).to have_content "local"

      shipping_method = Spree::ShippingMethod.find_by(name: 'Teleport')
      expect(shipping_method.distributors).to eq([distributor1])
      expect(shipping_method.tag_list).to eq(["local"])
    end

    it "shows me only shipping methods I have access to" do
      shipping_method1
      shipping_method2
      sm3

      visit spree.admin_shipping_methods_path

      expect(page).to     have_content shipping_method1.name
      expect(page).to     have_content shipping_method2.name
      expect(page).not_to have_content sm3.name
    end

    it "does not show duplicates of shipping methods" do
      shipping_method1
      shipping_method2

      visit spree.admin_shipping_methods_path

      expect(page).to have_selector 'td', text: 'Two', count: 1
    end

    it "shows me only shipping methods for the enterprise I select" do
      shipping_method1
      shipping_method2

      visit admin_enterprises_path
      within("#e_#{distributor1.id}") { click_link 'Settings' }

      within(".side_menu") do
        click_link "Shipping Methods"
      end

      expect(page).to have_content shipping_method1.name
      expect(page).to have_content shipping_method2.name

      expect(page).to have_checked_field "enterprise_shipping_method_ids_#{shipping_method2.id}"
      expect(page).to have_checked_field "enterprise_shipping_method_ids_#{shipping_method1.id}"

      click_link 'Enterprises'
      within("#e_#{distributor2.id}") { click_link 'Settings' }

      within(".side_menu") do
        click_link "Shipping Methods"
      end

      expect(page).to     have_content shipping_method1.name
      expect(page).to     have_content shipping_method2.name

      expect(page).to have_checked_field "enterprise_shipping_method_ids_#{shipping_method2.id}"
      expect(page).to have_unchecked_field "enterprise_shipping_method_ids_#{shipping_method1.id}"
    end
  end
end
