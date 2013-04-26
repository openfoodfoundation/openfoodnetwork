require 'spec_helper'

feature "enterprises distributor info as rich text" do
  include AuthenticationWorkflow
  include WebHelper

  before(:each) do
    ENV['OFW_DEPLOYMENT'] = 'local_organics'
  end


  scenario "setting distributor info as admin" do
    # Given I'm signed in as an admin
    login_to_admin_section

    # When I go to create a new enterprise
    click_link 'Enterprises'
    click_link 'New Enterprise'

    # Then I should see fields 'Profile Info' and 'Distributor Info'
    page.should have_selector 'td', text: 'Profile Info:'
    page.should have_selector 'td', text: 'Distributor Info:'

    # When I fill out the form and create the enterprise
    fill_in 'enterprise_name', :with => 'Eaterprises'
    fill_in 'enterprise_long_description', with: 'Zombie ipsum reversus ab viral inferno, nam rick grimes malum cerebro.'
    fill_in 'enterprise_distributor_info', with: 'Chu ge sai yubi dan bisento tobi ashi yubi ge omote.'
    fill_in 'enterprise_address_attributes_address1', with: '35 Ballantyne St'
    fill_in 'enterprise_address_attributes_city', with: 'Thornbury'
    fill_in 'enterprise_address_attributes_zipcode', with: '3072'
    select 'Australia', from: 'enterprise_address_attributes_country_id'
    select 'Victoria', from: 'enterprise_address_attributes_state_id'

    click_button 'Create'

    # Then I should see the enterprise details
    flash_message.should == 'Enterprise "Eaterprises" has been successfully created!'
    click_link 'Eaterprises'
    page.should have_selector "tr[data-hook='long_description'] th", text: 'Profile Info:'
    page.should have_selector "tr[data-hook='long_description'] td", text: 'Zombie ipsum reversus ab viral inferno, nam rick grimes malum cerebro.'

    page.should have_selector "tr[data-hook='distributor_info'] th", text: 'Distributor Info:'
    page.should have_selector "tr[data-hook='distributor_info'] td", text: 'Chu ge sai yubi dan bisento tobi ashi yubi ge omote.'
  end

  scenario "viewing distributor info" do
    d = create(:distributor_enterprise, distributor_info: 'Chu ge sai yubi dan bisento tobi ashi yubi ge omote.', next_collection_at: 'Thursday 2nd May')
    p = create(:product, :distributors => [d])

    login_to_consumer_section
    visit spree.select_distributor_order_path(d)

    # -- Product details page
    visit spree.product_path p
    within '#product-distributor-details' do
      page.should have_content 'Chu ge sai yubi dan bisento tobi ashi yubi ge omote.'
      page.should have_content 'Thursday 2nd May'
    end

    # -- Checkout
    click_button 'Add To Cart'
    click_link 'Checkout'
    within 'fieldset#shipping' do
      page.should have_content 'Chu ge sai yubi dan bisento tobi ashi yubi ge omote.'
      page.should have_content 'Thursday 2nd May'
    end
  end
end
