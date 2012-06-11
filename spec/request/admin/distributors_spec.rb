require "spec_helper"

feature %q{
    As an administration
    I want manage the distributors of products
} do
  include AuthenticationWorkflow
  include WebHelper

  background do
  end

  context "Given I am setting up distributors" do
    scenario "I should be able to create a new distributor" do
      login_to_admin_section

      click_link 'Distributors'
      click_link 'New Distributor'

      fill_in 'distributor_name', :with => 'Eaterprises'
      fill_in 'distributor_description', :with => 'Connecting farmers and eaters'
      fill_in 'distributor_contact', :with => 'Kirsten or Ren'
      fill_in 'distributor_phone', :with => '0413 897 321'
      fill_in 'distributor_pickup_address', :with => '35 Ballantyne St'
      fill_in 'distributor_city', :with => 'Thornbury'
      fill_in 'distributor_post_code', :with => '3072'
      select('Australia', :from => 'distributor_country_id')
      select('Victoria', :from => 'distributor_state_id')
      fill_in 'distributor_pickup_times', :with => 'Thursday, 22nd Feb, 6 - 9 PM. Friday, 23nd Feb, 6 - 9 PM'
      fill_in 'distributor_email', :with => 'info@eaterprises.com.au'
      fill_in 'distributor_url', :with => 'http://eaterprises.com.au'
      fill_in 'distributor_abn', :with => '09812309823'
      fill_in 'distributor_acn', :with => ''

      click_button 'Create'

      flash_message.should == 'Distributor "Eaterprises" has been successfully created!'
    end
  end
end
