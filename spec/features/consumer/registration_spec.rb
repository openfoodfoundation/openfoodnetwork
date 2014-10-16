require 'spec_helper'

feature "Registration", js: true do
  include WebHelper

  # TODO fix this after removal of is_distributor.
  pending "Registering a Profile" do
    let(:user) { create(:user, password: "password", password_confirmation: "password") }

    it "Allows a logged in user to register a profile" do
      visit registration_path

      expect(URI.parse(current_url).path).to eq registration_auth_path

      page.has_selector? "dd", text: "Log in"
      switch_to_login_tab

      # Enter Login details
      fill_in "Email", with: user.email
      fill_in "Password", with: user.password
      click_login_and_ensure_content "This wizard will step you through creating a profile"

      expect(URI.parse(current_url).path).to eq registration_path

      # Done reading introduction
      click_button_and_ensure_content "Let's get started!", "Woot! First we need to know a little bit about your enterprise:"

      # Filling in details
      fill_in 'enterprise_name', with: "My Awesome Enterprise"

      # Filling in address
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

      # Choosing a type
      expect(page).to have_content 'Last step to create your enterprise!'
      click_link 'both-panel'
      click_button 'Continue'

      # Enterprise should be created
      expect(page).to have_content 'Nice one!'
      e = Enterprise.find_by_name('My Awesome Enterprise')
      expect(e.address.address1).to eq "123 Abc Street"
      expect(e.sells).to eq "none"
      expect(e.is_primary_producer).to eq true
      expect(e.contact).to eq "Saskia Munroe"

      # Filling in about
      fill_in 'enterprise_description', with: 'Short description'
      fill_in 'enterprise_long_desc', with: 'Long description'
      fill_in 'enterprise_abn', with: '12345'
      fill_in 'enterprise_acn', with: '54321'
      click_button 'Continue'

      # Enterprise should be update
      expect(page).to have_content "Let's upload some pretty pictures so your profile looks great!"
      e.reload
      expect(e.description).to eq "Short description"
      expect(e.long_description).to eq "Long description"
      expect(e.abn).to eq '12345'
      expect(e.acn).to eq '54321'

      # Images
      # Move from logo page
      click_button 'Continue'
      # Move from promo page
      click_button 'Continue'

      # Filling in social
      expect(page).to have_content 'Almost there!'
      fill_in 'enterprise_website', with: 'www.shop.com'
      fill_in 'enterprise_facebook', with: 'FaCeBoOk'
      fill_in 'enterprise_linkedin', with: 'LiNkEdIn'
      fill_in 'enterprise_twitter', with: '@TwItTeR'
      fill_in 'enterprise_instagram', with: '@InStAgRaM'
      click_button 'Continue'

      # Done
      expect(page).to have_content "That's all of the details we need for My Awesome Enterprise"
      e.reload
      expect(e.website).to eq "www.shop.com"
      expect(e.facebook).to eq "FaCeBoOk"
      expect(e.linkedin).to eq "LiNkEdIn"
      expect(e.twitter).to eq "@TwItTeR"
      expect(e.instagram).to eq "@InStAgRaM"
    end

    it "Allows a logged in user to register a store" do
      visit store_registration_path

      expect(URI.parse(current_url).path).to eq registration_auth_path

      page.has_selector? "dd", text: "Log in"
      switch_to_login_tab

      # Enter Login details
      fill_in "Email", with: user.email
      fill_in "Password", with: user.password
      click_login_and_ensure_content "This wizard will step you through creating a profile"

      expect(URI.parse(current_url).path).to eq store_registration_path

      # Done reading introduction
      click_button_and_ensure_content "Let's get started!", "Woot! First we need to know a little bit about your farm:"

      # Details Page
      expect(page).to_not have_selector '#enterprise-types'

      # Everything from here should be covered in 'profile' spec
    end
  end

  def switch_to_login_tab
    # Link appears to be unresponsive for a while, so keep clicking it until it works
    using_wait_time 0.5 do
      10.times do
        click_link "Log in"
        break if page.has_selector? "dd.active", text: "Log in"
      end
    end
  end

  def click_login_and_ensure_content(content)
    # Buttons appear to be unresponsive for a while, so keep clicking them until content appears
    using_wait_time 1 do
      3.times do
        click_button "Log in"
        break if page.has_selector? "div#loading", text: "Hold on a moment, we're logging you in"
      end
    end
    expect(page).to have_content content
  end

  def click_button_and_ensure_content(button_text, content)
    # Buttons appear to be unresponsive for a while, so keep clicking them until content appears
    using_wait_time 0.5 do
      10.times do
        click_button button_text
        break if page.has_content? content
      end
    end
  end
end
