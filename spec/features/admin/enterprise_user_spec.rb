require "spec_helper"

feature %q{
    As a Super User
    I want to setup users to manage an enterprise
} do
  include AuthenticationWorkflow
  include WebHelper

  before(:each) do
    @new_user = create_enterprise_user
    @supplier1 = create(:supplier_enterprise, name: 'Supplier 1')
    @supplier2 = create(:supplier_enterprise, name: 'Supplier 2')
    @distributor1 = create(:distributor_enterprise, name: 'Distributor 3')
    @distributor2 = create(:distributor_enterprise, name: 'Distributor 4')
  end

  context "creating an Enterprise User" do
    context 'with no enterprises' do
      scenario "assigning a user to an Enterprise" do
        login_to_admin_section
        click_link 'Users'
        click_link @new_user.email
        click_link 'Edit'

        check @supplier2.name

        click_button 'Update'
        @new_user.enterprises.count.should == 1
        @new_user.enterprises.first.name.should == @supplier2.name
      end

    end

    context 'with existing enterprises' do

      before(:each) do
        @new_user.enterprise_roles.build(enterprise: @supplier1).save
        @new_user.enterprise_roles.build(enterprise: @distributor1).save
      end

      scenario "removing and add enterprises for a user" do
        login_to_admin_section

        click_link 'Users'
        click_link @new_user.email
        click_link 'Edit'

        uncheck @distributor1.name # remove
        check @distributor2.name # add

        click_button 'Update'

        @new_user.enterprises.count.should == 2
        @new_user.enterprises.should include(@supplier1)
        @new_user.enterprises.should include(@distributor2)
      end

    end

  end

  context "Product management" do

    context 'products I supply' do
      before(:each) do
        @new_user.enterprise_roles.build(enterprise: @supplier1).save
        product1 = create(:product, name: 'Green eggs', supplier: @supplier1)
        product2 = create(:product, name: 'Ham', supplier: @supplier2)
        login_to_admin_as @new_user
      end

      scenario "manage products that I supply" do
        visit '/admin/products'

        within '#listing_products' do
          page.should have_content 'Green eggs'
          page.should_not have_content 'Ham'
        end
      end
    end

  end

  context "System management lockdown" do

    before(:each) do
      @new_user.enterprise_roles.build(enterprise: @supplier1).save
      login_to_admin_as @new_user
    end

    scenario "should not be able to see system configuration" do
      visit '/admin/general_settings/edit'
      page.should have_content 'Unauthorized'
    end

    scenario "should not be able to see user management" do
      visit '/admin/users'
      page.should have_content 'Unauthorized'
    end
  end
end
