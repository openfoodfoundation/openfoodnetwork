require "spec_helper"

feature %q{
    As an administration
    I want manage the suppliers of products
} do
  include AuthenticationWorkflow
  include WebHelper

  background do
  end

  context "setting up suppliers" do
    scenario "creating a new supplier" do
      login_to_admin_section

      click_link 'Suppliers'
      click_link 'New Supplier'

      fill_in 'supplier_name', :with => 'David Arnold'
      fill_in 'supplier_description', :with => 'A farmer with a difference'

      fill_in 'supplier_address_attributes_address1', :with => '35 Byron Ave'
      fill_in 'supplier_address_attributes_city', :with => 'Ararat'
      fill_in 'supplier_address_attributes_zipcode', :with => '1112'
      select('Australia', :from => 'supplier_address_attributes_country_id')
      select('Victoria', :from => 'supplier_address_attributes_state_id')

      fill_in 'supplier_email', :with => 'david@here.com'
      fill_in 'supplier_website', :with => 'http://somewhere.com'
      fill_in 'supplier_twitter', :with => 'davida'

      click_button 'Create'

      flash_message.should == 'Supplier "David Arnold" has been successfully created!'
    end
  end
end
