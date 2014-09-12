require 'spec_helper'

feature "Registration", js: true do
  include WebHelper

  describe "Registering a Profile" do
    let(:user) { create(:user, password: "password", password_confirmation: "password") }

    it "Allows a logged in user to register a profile" do
      visit registration_path

      expect(URI.parse(current_url).path).to eq registration_auth_path
      # Prevent race condition - "Log in" link is visible, but early click events are lost
      # without some delay here
      page.should have_link "Log in"

      # Logging in
      click_link "Log in"
      #page.should have_button 'Log in'

      fill_in "Email", with: user.email
      fill_in "Password", with: user.password

      # unless page.has_button? 'Log in'
      #   save_screenshot('/home/rohan/ss.png', full: true)
      #   binding.pry
      # end

      click_button 'Log in'

      # Log in was successful, introduction shown
      expect(page).to have_content "This wizard will step you through creating a profile"
      expect(URI.parse(current_url).path).to eq registration_path

      # Done reading introduction
      click_button "Let's get started!"

      # Filling in details
      expect(page).to have_content "Woot! First we need to know what sort of enterprise you are:"
      fill_in 'enterprise_name', with: "My Awesome Enterprise"
      click_link 'both-panel'
      click_button 'Continue'

      # Filling in address
      expect(page).to have_content 'Greetings My Awesome Enterprise'
      fill_in 'enterprise_address', with: '123 Abc Street'
      fill_in 'enterprise_city', with: 'Northcote'
      fill_in 'enterprise_zipcode', with: '3070'
      select 'Australia', from: 'enterprise_country'
      select 'Vic', from: 'enterprise_state'
      click_button 'Continue'

      # Filling in Contact Details
      expect(page).to have_content 'Who is responsible for managing My Awesome Enterprise?'
      fill_in 'enterprise_contact', with: 'Saskia Munroe'
      page.should have_field 'enterprise_email', with: user.email
      fill_in 'enterprise_phone', with: '12 3456 7890'
      click_button 'Continue'

      # Enterprise should be created
      expect(page).to have_content 'Nice one!'
      # e = Enterprise.find_by_name('My Awesome Enterprise')
      # expect(e.address.address1).to eq "123 Abc Street"
      # expect(e.is_distributor).to eq true
      # expect(e.is_primary_producer).to eq true
      # expect(e.contact).to eq "Saskia Munroe"

      # Filling in about
      fill_in 'enterprise_description', with: 'Short description'
      fill_in 'enterprise_long_desc', with: 'Long description'
      fill_in 'enterprise_abn', with: '12345'
      fill_in 'enterprise_acn', with: '54321'
      click_button 'Continue'

      # Enterprise should be updated
      expect(page).to have_content 'Last step!'
      # e.reload
      # expect(e.description).to eq "Short description"
      # expect(e.long_description).to eq "Long description"
      # expect(e.abn).to eq '12345'
      # expect(e.acn).to eq '54321'

      # Filling in social
      fill_in 'enterprise_website', with: 'www.shop.com'
      fill_in 'enterprise_facebook', with: 'FaCeBoOk'
      fill_in 'enterprise_linkedin', with: 'LiNkEdIn'
      fill_in 'enterprise_twitter', with: '@TwItTeR'
      fill_in 'enterprise_instagram', with: '@InStAgRaM'
      click_button 'Continue'

      # Done
      expect(page).to have_content "You have successfully completed the profile for My Awesome Enterprise"
      # e.reload
      # expect(e.website).to eq "www.shop.com"
      # expect(e.facebook).to eq "FaCeBoOk"
      # expect(e.linkedin).to eq "LiNkEdIn"
      # expect(e.twitter).to eq "@TwItTeR"
      # expect(e.instagram).to eq "@InStAgRaM"
    end

    it "Allows a logged in user to register a store" do
      visit store_registration_path

      expect(URI.parse(current_url).path).to eq registration_auth_path

      # Logging in
      click_link "Log in"
      fill_in "Email", with: user.email
      fill_in "Password", with: user.password
      click_button 'Log in'

      # Log in was successful, introduction shown
      expect(page).to have_content "This wizard will step you through creating a profile"
      expect(URI.parse(current_url).path).to eq store_registration_path

      # Done reading introduction
      click_button "Let's get started!"

      # Details Page
      expect(page).to have_content "Woot! First we need to know the name of your farm:"
      expect(page).to_not have_selector '#enterprise-types'

      # Everything from here should be covered in 'profile' spec
    end
  end
end
