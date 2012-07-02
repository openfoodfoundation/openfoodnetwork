require "spec_helper"

feature %q{
    As an administration
    I want manage the distributors of products
} do
  include AuthenticationWorkflow
  include WebHelper


  scenario "creating a new distributor" do
    login_to_admin_section

    click_link 'Distributors'
    click_link 'New Distributor'

    fill_in 'distributor_name', :with => 'Eaterprises'
    fill_in 'distributor_description', :with => 'Connecting farmers and eaters'
    fill_in 'distributor_contact', :with => 'Kirsten or Ren'
    fill_in 'distributor_phone', :with => '0413 897 321'

    fill_in 'distributor_pickup_address_attributes_address1', :with => '35 Ballantyne St'
    fill_in 'distributor_pickup_address_attributes_city', :with => 'Thornbury'
    fill_in 'distributor_pickup_address_attributes_zipcode', :with => '3072'
    select('Australia', :from => 'distributor_pickup_address_attributes_country_id')
    select('Victoria', :from => 'distributor_pickup_address_attributes_state_id')

    fill_in 'distributor_pickup_times', :with => 'Thursday, 22nd Feb, 6 - 9 PM. Friday, 23nd Feb, 6 - 9 PM'
    fill_in 'distributor_email', :with => 'info@eaterprises.com.au'
    fill_in 'distributor_url', :with => 'http://eaterprises.com.au'
    fill_in 'distributor_abn', :with => '09812309823'
    fill_in 'distributor_acn', :with => ''

    click_button 'Create'

    flash_message.should == 'Distributor "Eaterprises" has been successfully created!'
  end


  scenario "updating many distributor next collection times at once" do
    # Given three distributors
    3.times { create(:distributor) }

    # When I go to the distributors page
    login_to_admin_section
    click_link 'Distributors'

    # And I fill in some new collection times and save them
    fill_in 'distributor_set_distributors_attributes_0_next_collection_at', :with => 'One'
    fill_in 'distributor_set_distributors_attributes_1_next_collection_at', :with => 'Two'
    fill_in 'distributor_set_distributors_attributes_2_next_collection_at', :with => 'Three'
    click_button 'Update'

    # Then my times should have been saved
    flash_message.should == 'Distributor collection times updated.'
    Spree::Distributor.all.map { |d| d.next_collection_at }.should == %w(One Two Three)
  end

end
