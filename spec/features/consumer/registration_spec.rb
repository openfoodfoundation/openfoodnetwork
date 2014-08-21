require 'spec_helper'

feature "Registration", js: true do
  describe "Registering a Profile" do
    let(:user) { create(:user, password: "password", password_confirmation: "password") }

    it "Allows a logged in user to register a profile" do
      visit registration_path

      expect(URI.parse(current_url).path).to eq registration_auth_path

      # Logging in
      fill_in "Email", with: user.email
      fill_in "Password", with: user.password
      click_button 'Log in'
      
      # Log in was successful, introduction shown
      expect(page).to have_content "This wizard will step you through creating a Profile on the Open Food Network."
      expect(URI.parse(current_url).path).to eq registration_path

      # Done reading introduction
      click_button "Let's get started!"
      
      # Filling in details
      expect(page).to have_content "Woot! First we need to know what sort of enterprise you are:"
      fill_in 'enterprise_name', with: "My Awesome Enterprise"
      click_link 'both'
      click_button 'Continue'

      # Filling in address
      expect(page).to have_content 'My Awesome Enterprise'
      fill_in 'enterprise_address', with: '123 Abc Street'
      fill_in 'enterprise_city', with: 'Northcote'
      fill_in 'enterprise_zipcode', with: '3070'
      fill_in 'enterprise_country', with: 'Australia'
      fill_in 'enterprise_state', with: 'Victoria'
      click_button 'Continue'

      # Filling in Contact Details
      expect(page).to have_content 'Who is responsible for managing My Awesome Enterprise?'
      fill_in 'enterprise_contact', with: 'Saskia Munroe'
      page.should have_field 'enterprise_email', with: user.email
      fill_in 'enterprise_phone', with: '12 3456 7890'
      click_button 'Continue'

      # Enterprise should be created
      sleep 10
      save_screenshot '/Users/rob/Desktop/ss.png'
      expect(page).to have_content 'Yay! You created an enterprise!'
    end
  end
end
      