require 'spec_helper'

feature 'shipping methods' do
  include AuthenticationWorkflow
  include WebHelper

  before :each do
    @sm = create(:shipping_method)
  end

  context "as a site admin" do
    before(:each) do
      login_to_admin_section
    end

    scenario "creating a shipping method owned by some distributors" do
      # Given some distributors
      d1 = create(:distributor_enterprise, name: 'Aeronautical Adventures')
      d2 = create(:distributor_enterprise, name: 'Nautical Travels')

      # Shows appropriate fields when logged in as admin
      visit spree.new_admin_shipping_method_path
      page.should have_field 'shipping_method_name'
      page.should have_field 'shipping_method_description'
      page.should have_select 'shipping_method_display_on'
      page.should have_field 'shipping_method_require_ship_address_true', checked: true

      # When I create a shipping method and set the distributors
      fill_in 'shipping_method_name', with: 'Carrier Pidgeon'
      check "shipping_method_distributor_ids_#{d1.id}"
      check "shipping_method_distributor_ids_#{d2.id}"
      click_button 'Create'

      # Then the shipping method should have its distributor set
      flash_message.should == 'Shipping method "Carrier Pidgeon" has been successfully created!'

      sm = Spree::ShippingMethod.last
      sm.name.should == 'Carrier Pidgeon'
      sm.distributors.should match_array [d1, d2]
    end

    it "at checkout, user can only see shipping methods for their current distributor (checkout spec)"


    scenario "deleting a shipping method" do
      visit_delete spree.admin_shipping_method_path(@sm)

      page.should have_content "Shipping method \"#{@sm.name}\" has been successfully removed!"
      Spree::ShippingMethod.where(:id => @sm.id).should be_empty
    end

    scenario "deleting a shipping method referenced by an order" do
      o = create(:order)
      o.shipping_method = @sm
      o.save!

      visit_delete spree.admin_shipping_method_path(@sm)

      page.should have_content "That shipping method cannot be deleted as it is referenced by an order: #{o.number}."
      Spree::ShippingMethod.find(@sm.id).should_not be_nil
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
      login_to_admin_as enterprise_user
    end

    it "creating a shipping method" do
      click_link 'Enterprises'
      within("#e_#{distributor1.id}") { click_link 'Manage' }
      within(".side_menu") do
        click_link "Shipping Methods"
      end
      click_link 'Create One Now'

      # Show the correct fields
      page.should have_field 'shipping_method_name'
      page.should have_field 'shipping_method_description'
      page.should_not have_select 'shipping_method_display_on'
      page.should have_field 'shipping_method_require_ship_address_true', checked: true

      fill_in 'shipping_method_name', :with => 'Teleport'

      check "shipping_method_distributor_ids_#{distributor1.id}"
      find(:css, "tags-input .tags input").set "local\n"

      click_button 'Create'

      flash_message.should == 'Shipping method "Teleport" has been successfully created!'
      expect(first('tags-input .tag-list ti-tag-item')).to have_content "local"

      shipping_method = Spree::ShippingMethod.find_by_name('Teleport')
      shipping_method.distributors.should == [distributor1]
      shipping_method.tag_list.should == ["local"]
    end

    it "shows me only shipping methods I have access to" do
      sm1
      sm2
      sm3

      visit spree.admin_shipping_methods_path

      page.should     have_content sm1.name
      page.should     have_content sm2.name
      page.should_not have_content sm3.name
    end

    it "does not show duplicates of shipping methods" do
      sm1
      sm2

      visit spree.admin_shipping_methods_path

      page.should have_selector 'td', text: 'Two', count: 1
    end

    pending "shows me only shipping methods for the enterprise I select" do
      sm1
      sm2

      click_link 'Enterprises'
      within("#e_#{distributor1.id}") { click_link 'Manage' }
      within(".side_menu") do
        click_link "Shipping Methods"
      end
      page.should     have_content sm1.name
      page.should     have_content sm2.name

      click_link 'Enterprises'
      within("#e_#{distributor2.id}") { click_link 'Manage' }
      within(".side_menu") do
        click_link "Shipping Methods"
      end

      page.should_not have_content sm1.name
      page.should     have_content sm2.name
    end
  end
end
