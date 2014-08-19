require "spec_helper"

feature %q{
    As a Super User
    I want to setup users to manage an enterprise
} do
  include AuthenticationWorkflow
  include WebHelper
  include AdminHelper

  let!(:user) { create_enterprise_user }
  let!(:supplier1) { create(:supplier_enterprise, name: 'Supplier 1') }
  let!(:supplier2) { create(:supplier_enterprise, name: 'Supplier 2') }
  let(:supplier_profile) { create(:supplier_enterprise, name: 'Supplier profile', type: 'profile') }
  let!(:distributor1) { create(:distributor_enterprise, name: 'Distributor 3') }
  let!(:distributor2) { create(:distributor_enterprise, name: 'Distributor 4') }

  describe "creating an enterprise user" do
    context "with no enterprises managed" do
      it "assigns an enterprise to a user" do
        login_to_admin_section
        click_link 'Users'
        click_link user.email
        click_link 'Edit'

        check supplier2.name

        click_button 'Update'
        user.enterprises.count.should == 1
        user.enterprises.first.name.should == supplier2.name
      end
    end

    context "with existing enterprises managed" do
      before do
        user.enterprise_roles.create!(enterprise: supplier1)
        user.enterprise_roles.create!(enterprise: distributor1)
      end

      it "can remove and add enterprise management for a user" do
        login_to_admin_section

        click_link 'Users'
        click_link user.email
        click_link 'Edit'

        uncheck distributor1.name # remove
        check distributor2.name # add

        click_button 'Update'

        user.enterprises.count.should == 2
        user.enterprises.should include supplier1
        user.enterprises.should include distributor2
      end
    end
  end

  describe "product management" do
    describe "managing supplied products" do
      before do
        user.enterprise_roles.create!(enterprise: supplier1)
        product1 = create(:product, name: 'Green eggs', supplier: supplier1)
        product2 = create(:product, name: 'Ham', supplier: supplier2)
        login_to_admin_as user
      end

      it "can manage products that I supply" do
        visit spree.admin_products_path

        within '#listing_products' do
          page.should have_content 'Green eggs'
          page.should_not have_content 'Ham'
        end
      end
    end
  end

  describe "with only a profile-level enterprise" do
    before do
      user.enterprise_roles.create! enterprise: supplier_profile
      login_to_admin_as user
    end

    it "shows me only menu items for enterprise management" do
      page.should have_admin_menu_item 'Dashboard'
      page.should have_admin_menu_item 'Enterprises'

      ['Orders', 'Products', 'Reports', 'Configuration', 'Promotions', 'Users', 'Order Cycles'].each do |menu_item_name|
        page.should_not have_admin_menu_item menu_item_name
      end
    end

    it "shows me a cut-down dashboard"
    it "shows me only profile options on the enterprises page"
  end

  describe "system management lockdown" do
    before do
      user.enterprise_roles.create!(enterprise: supplier1)
      login_to_admin_as user
    end

    scenario "should not be able to see system configuration" do
      visit spree.edit_admin_general_settings_path
      page.should have_content 'Unauthorized'
    end

    scenario "should not be able to see user management" do
      visit spree.admin_users_path
      page.should have_content 'Unauthorized'
    end
  end
end
