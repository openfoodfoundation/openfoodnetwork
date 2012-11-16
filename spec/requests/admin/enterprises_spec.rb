require "spec_helper"

feature %q{
    As an administrator
    I want manage enterprises
} do
  include AuthenticationWorkflow
  include WebHelper


  scenario "listing enterprises" do
    e = create(:enterprise)

    login_to_admin_section
    click_link 'Enterprises'

    page.should have_content e.name
  end

  scenario "viewing an enterprise" do
    e = create(:enterprise)

    login_to_admin_section
    click_link 'Enterprises'
    click_link e.name

    page.should have_content e.name
  end

  scenario "creating a new enterprise" do
    login_to_admin_section

    click_link 'Enterprises'
    click_link 'New Enterprise'

    fill_in 'enterprise_name', :with => 'Eaterprises'
    fill_in 'enterprise_description', :with => 'Connecting farmers and eaters'
    fill_in 'enterprise_long_description', :with => 'Zombie ipsum reversus ab viral inferno, nam rick grimes malum cerebro.'

    uncheck 'enterprise_is_primary_producer'
    check 'enterprise_is_distributor'

    fill_in 'enterprise_contact', :with => 'Kirsten or Ren'
    fill_in 'enterprise_phone', :with => '0413 897 321'
    fill_in 'enterprise_email', :with => 'info@eaterprises.com.au'
    fill_in 'enterprise_website', :with => 'http://eaterprises.com.au'
    fill_in 'enterprise_twitter', :with => '@eaterprises'
    fill_in 'enterprise_abn', :with => '09812309823'
    fill_in 'enterprise_acn', :with => ''

    fill_in 'enterprise_address_attributes_address1', :with => '35 Ballantyne St'
    fill_in 'enterprise_address_attributes_city', :with => 'Thornbury'
    fill_in 'enterprise_address_attributes_zipcode', :with => '3072'
    select('Australia', :from => 'enterprise_address_attributes_country_id')
    select('Victoria', :from => 'enterprise_address_attributes_state_id')

    fill_in 'enterprise_pickup_times', :with => 'Thursday, 22nd Feb, 6 - 9 PM. Friday, 23nd Feb, 6 - 9 PM'
    fill_in 'enterprise_next_collection_at', :with => 'Thursday, 22nd Feb, 6 - 9 PM'

    click_button 'Create'

    flash_message.should == 'Enterprise "Eaterprises" has been successfully created!'
  end

  scenario "editing an existing enterprise" do
    @enterprise = create(:enterprise)

    login_to_admin_section

    click_link 'Enterprises'
    click_link 'Edit'

    fill_in 'enterprise_name', :with => 'Eaterprises'
    fill_in 'enterprise_description', :with => 'Connecting farmers and eaters'
    fill_in 'enterprise_long_description', :with => 'Zombie ipsum reversus ab viral inferno, nam rick grimes malum cerebro.'

    uncheck 'enterprise_is_primary_producer'
    check 'enterprise_is_distributor'

    fill_in 'enterprise_contact', :with => 'Kirsten or Ren'
    fill_in 'enterprise_phone', :with => '0413 897 321'
    fill_in 'enterprise_email', :with => 'info@eaterprises.com.au'
    fill_in 'enterprise_website', :with => 'http://eaterprises.com.au'
    fill_in 'enterprise_twitter', :with => '@eaterprises'
    fill_in 'enterprise_abn', :with => '09812309823'
    fill_in 'enterprise_acn', :with => ''

    fill_in 'enterprise_address_attributes_address1', :with => '35 Ballantyne St'
    fill_in 'enterprise_address_attributes_city', :with => 'Thornbury'
    fill_in 'enterprise_address_attributes_zipcode', :with => '3072'
    select('Australia', :from => 'enterprise_address_attributes_country_id')
    select('Victoria', :from => 'enterprise_address_attributes_state_id')

    fill_in 'enterprise_pickup_times', :with => 'Thursday, 22nd Feb, 6 - 9 PM. Friday, 23nd Feb, 6 - 9 PM'
    fill_in 'enterprise_next_collection_at', :with => 'Thursday, 22nd Feb, 6 - 9 PM'

    click_button 'Update'

    flash_message.should == 'Enterprise "Eaterprises" has been successfully updated!'
  end


  scenario "updating many distributor next collection times at once" do
    # Given three distributors
    3.times { create(:distributor_enterprise) }

    # When I go to the enterprises page
    login_to_admin_section
    click_link 'Enterprises'

    # And I fill in some new collection times and save them
    fill_in 'enterprise_set_enterprises_attributes_0_next_collection_at', :with => 'One'
    fill_in 'enterprise_set_enterprises_attributes_1_next_collection_at', :with => 'Two'
    fill_in 'enterprise_set_enterprises_attributes_2_next_collection_at', :with => 'Three'
    click_button 'Update'

    # Then my times should have been saved
    flash_message.should == 'Distributor collection times updated.'
    Enterprise.is_distributor.map { |d| d.next_collection_at }.should == %w(One Two Three)
  end

end
