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
  let(:supplier_profile) { create(:supplier_enterprise, name: 'Supplier profile', sells: 'none') }
  let!(:distributor1) { create(:distributor_enterprise, name: 'Distributor 3') }
  let!(:distributor2) { create(:distributor_enterprise, name: 'Distributor 4') }
  let(:distributor_profile) { create(:distributor_enterprise, name: 'Distributor profile', sells: 'none') }

  describe "creating an enterprise user" do
    context "with a limitted number of owned enterprises" do
      scenario "setting the enterprise ownership limit" do
        user.enterprise_limit.should == 1
        login_to_admin_section
        click_link 'Users'
        click_link user.email

        fill_in "user_enterprise_limit", with: 2

        click_button 'Update'
        user.reload
        expect(user.enterprise_limit).to eq 2
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

  # This case no longer exists as anyone with an enterprise can supply into the system. 
  # Or can they?? There is no producer profile anyway.
  # TODO discuss what parts of this are still necessary in which cases.
  pending "with only a profile-level enterprise" do
    before do
      user.enterprise_roles.create! enterprise: supplier_profile
      user.enterprise_roles.create! enterprise: distributor_profile
      login_to_admin_as user
    end

    it "shows me only menu items for enterprise management" do
      page.should have_admin_menu_item 'Dashboard'
      page.should have_admin_menu_item 'Enterprises'

      ['Orders', 'Reports', 'Configuration', 'Promotions', 'Users', 'Order Cycles'].each do |menu_item_name|
        page.should_not have_admin_menu_item menu_item_name
      end
    end

    describe "dashboard" do
      it "shows me enterprise management controls" do
        within('#enterprises') do
          page.should have_selector 'h3', text: 'My Enterprises'
          page.should have_link 'CREATE NEW'
          page.should have_link supplier_profile.name
          page.should have_link 'MANAGE MY ENTERPRISES'
        end
      end

      it "shows me product management controls, but not order_cycle controls" do
        page.should have_selector '#products'
        page.should_not have_selector '#order_cycles'
      end

      it "shows me enterprise product info but not payment methods, shipping methods or enterprise fees" do
        # Producer product info
        page.should have_selector '.producers_tab span', text: 'Total Products'
        page.should have_selector '.producers_tab span', text: 'Active Products'
        page.should_not have_selector '.producers_tab span', text: 'Products in OCs'

        # Payment methods, shipping methods, enterprise fees
        page.should_not have_selector '.hubs_tab span', text: 'Payment Methods'
        page.should_not have_selector '.hubs_tab span', text: 'Shipping Methods'
        page.should_not have_selector '.hubs_tab span', text: 'Enterprise Fees'
      end
    end

    it "shows me only profile options on the enterprise listing page" do
      click_link 'Enterprises'

      within "tr.enterprise-#{supplier_profile.id}" do
        page.should_not have_link 'Enterprise Fees'
      end

      within "tr.enterprise-#{distributor_profile.id}" do
        page.should_not have_link 'Payment Methods'
        page.should_not have_link 'Shipping Methods'
        page.should_not have_link 'Enterprise Fees'
      end
    end

    it "shows me only profile fields on the hub edit page" do
      click_link distributor_profile.name

      page.should_not have_selector '#payment_methods'
      page.should_not have_selector '#shipping_methods'
      page.should_not have_selector '#enterprise_fees'
    end
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
