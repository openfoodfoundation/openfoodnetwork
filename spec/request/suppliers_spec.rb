require "spec_helper"

feature %q{
    As an administration
    I want manage the suppliers of products
} do
  # include AuthenticationWorkflow
  # include WebHelper

  background do
  end

  context "Given I am setting up suppliers" do
    scenario "I should be able to create a new supplier" do
      admin_role = Spree::Role.create(:name => 'admin')
      admin_user = Spree::User.create({
        :email => 'admin@ofw.org',
        :password => 'passw0rd',
        :password_confirmation => 'passw0rd',
        :remember_me => false,
        :persistence_token => 'pass',
        :login => 'admin@ofw.org',
        :role_ids => [admin_role.id]})

      visit spree.admin_path
      fill_in 'user_email', :with => 'admin@ofw.org'
      fill_in 'user_password', :with => 'passw0rd'
      click_button 'Login'

      click_link 'Suppliers'
      click_link 'New Supplier'

      fill_in 'supplier_name', :with => 'David arnold'
      fill_in 'supplier_description', :with => 'A farmer with a difference'
      fill_in 'supplier_address', :with => '35 Byron Ave'
      fill_in 'supplier_city', :with => 'Ararat'
      fill_in 'supplier_postcode', :with => '1112'
      select('Australia', :from => 'supplier_country_id')
      select('Victoria', :from => 'supplier_state_id')
      fill_in 'supplier_email', :with => 'david@here.com'
      fill_in 'supplier_website', :with => 'http://somewhere.com'
      fill_in 'supplier_twitter', :with => 'davida'

      click_button 'Create'

      find('.flash').text.strip.should == 'Supplier "David arnold" has been successfully created!'
    end
  end
end
