require 'spec_helper'

feature 'shipping methods' do
  include AuthenticationWorkflow
  include WebHelper

  before :each do
    @sm = create(:shipping_method)
  end

  context "as a site admin" do
    before(:each) do
      quick_login_as_admin
    end

    scenario "creating a shipping method owned by some distributors" do
      # Given some distributors
      d1 = create(:distributor_enterprise, name: 'Aeronautical Adventures')
      d2 = create(:distributor_enterprise, name: 'Nautical Travels')

      # Shows appropriate fields when logged in as admin
      visit spree.new_admin_shipping_method_path
      expect(page).to have_field 'shipping_method_name'
      expect(page).to have_field 'shipping_method_description'
      expect(page).to have_select 'shipping_method_display_on'
      expect(page).to have_css 'div#shipping_method_zones_field'
      expect(page).to have_field 'shipping_method_require_ship_address_true', checked: true

      # When I create a shipping method and set the distributors
      fill_in 'shipping_method_name', with: 'Carrier Pidgeon'
      check "shipping_method_distributor_ids_#{d1.id}"
      check "shipping_method_distributor_ids_#{d2.id}"
      check "shipping_method_shipping_categories_"
      click_button I18n.t("actions.create")

      expect(page).to have_no_button I18n.t("actions.create")

      # Then the shipping method should have its distributor set
      message = "Shipping method \"Carrier Pidgeon\" has been successfully created!"
      expect(page).to have_flash_message message

      sm = Spree::ShippingMethod.last
      expect(sm.name).to eq('Carrier Pidgeon')
      expect(sm.distributors).to match_array [d1, d2]
    end

    it "at checkout, user can only see shipping methods for their current distributor (checkout spec)"


    scenario "deleting a shipping method" do
      visit_delete spree.admin_shipping_method_path(@sm)

      expect(page).to have_content "Shipping method \"#{@sm.name}\" has been successfully removed!"
      expect(Spree::ShippingMethod.where(:id => @sm.id)).to be_empty
    end

    scenario "deleting a shipping method referenced by an order" do
      o = create(:order)
      shipment = create(:shipment)
      shipment.add_shipping_method(@sm, true)
      o.shipments << shipment
      o.save!

      visit_delete spree.admin_shipping_method_path(@sm)

      expect(page).to have_content "That shipping method cannot be deleted as it is referenced by an order: #{o.number}."
      expect(Spree::ShippingMethod.find(@sm.id)).not_to be_nil
    end
  end

  context "as an enterprise user", js: true do
    let(:enterprise_user) { create_enterprise_user }
    let(:distributor1) { create(:distributor_enterprise, name: 'First Distributor') }
    let(:distributor2) { create(:distributor_enterprise, name: 'Second Distributor') }
    let(:distributor3) { create(:distributor_enterprise, name: 'Third Distributor') }
    let(:sm1) { create(:shipping_method, name: 'One', distributors: [distributor1]) }
    let(:sm2) { create(:shipping_method, name: 'Two', distributors: [distributor1, distributor2]) }
    let(:sm3) { create(:shipping_method, name: 'Three', distributors: [distributor3]) }

    before(:each) do
      enterprise_user.enterprise_roles.build(enterprise: distributor1).save
      enterprise_user.enterprise_roles.build(enterprise: distributor2).save
      quick_login_as enterprise_user
    end

    it "creating a shipping method" do
      visit admin_enterprises_path
      within("#e_#{distributor1.id}") { click_link 'Settings' }
      within(".side_menu") do
        click_link "Shipping Methods"
      end
      click_link 'Create One Now'

      # Show the correct fields
      expect(page).to have_field 'shipping_method_name'
      expect(page).to have_field 'shipping_method_description'
      expect(page).not_to have_select 'shipping_method_display_on'
      expect(page).to have_css 'div#shipping_method_zones_field'
      expect(page).to have_field 'shipping_method_require_ship_address_true', checked: true

      fill_in 'shipping_method_name', :with => 'Teleport'

      check "shipping_method_distributor_ids_#{distributor1.id}"
      check "shipping_method_shipping_categories_"
      find(:css, "tags-input .tags input").set "local\n"
      within(".tags .tag-list") do
        expect(page).to have_css '.tag-item'
      end

      click_button I18n.t("actions.create")

      expect(page).to have_content I18n.t('spree.admin.shipping_methods.edit.editing_shipping_method')
      expect(flash_message).to eq I18n.t('successfully_created', resource: 'Shipping method "Teleport"')

      expect(first('tags-input .tag-list ti-tag-item')).to have_content "local"

      shipping_method = Spree::ShippingMethod.find_by_name('Teleport')
      expect(shipping_method.distributors).to eq([distributor1])
      expect(shipping_method.tag_list).to eq(["local"])
    end

    it "shows me only shipping methods I have access to" do
      sm1
      sm2
      sm3

      visit spree.admin_shipping_methods_path

      expect(page).to     have_content sm1.name
      expect(page).to     have_content sm2.name
      expect(page).not_to have_content sm3.name
    end

    it "does not show duplicates of shipping methods" do
      sm1
      sm2

      visit spree.admin_shipping_methods_path

      expect(page).to have_selector 'td', text: 'Two', count: 1
    end

    pending "shows me only shipping methods for the enterprise I select" do
      sm1
      sm2

      visit admin_enterprises_path
      within("#e_#{distributor1.id}") { click_link 'Settings' }
      within(".side_menu") do
        click_link "Shipping Methods"
      end
      expect(page).to     have_content sm1.name
      expect(page).to     have_content sm2.name

      click_link 'Enterprises'
      within("#e_#{distributor2.id}") { click_link 'Settings' }
      within(".side_menu") do
        click_link "Shipping Methods"
      end

      expect(page).not_to have_content sm1.name
      expect(page).to     have_content sm2.name
    end
  end
end
