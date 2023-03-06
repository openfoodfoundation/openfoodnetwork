# frozen_string_literal: true

require 'system_helper'

describe "Registration" do
  include AuthenticationHelper
  include WebHelper

  describe "Registering a Profile" do
    let(:user) { create(:user, password: "password", password_confirmation: "password") }

    before do
      Spree::Config.enterprises_require_tos = false

      albania = Spree::Country.create!({ name: "Albania", iso3: "ALB", iso: "AL",
                                         iso_name: "ALBANIA", numcode: "8" })
      Spree::State.create!({ name: "Berat", abbr: "BRA", country: albania })
      Spree::Country.create!({ name: "Chad", iso3: "TCD", iso: "TD", iso_name: "CHAD",
                               numcode: "148" })
      allow_any_instance_of(AddressGeocoder).to receive(:geocode)
    end

    after do
      Spree::State.where(name: 'Berat').delete_all
      Spree::Country.where(name: 'Albania').delete_all
      Spree::Country.where(name: 'Chad').delete_all
    end

    it "Allows a logged in user to register a profile" do
      visit registration_path

      expect(Spree::Config.enterprises_require_tos).to eq false
      expect(URI.parse(current_url).path).to eq registration_auth_path

      page.has_selector? "dd", text: "Login"
      switch_to_login_tab

      # Enter Login details
      fill_in "Email", with: user.email
      fill_in "Password", with: user.password

      click_button "Login"
      expect(page).to have_content("Hi there!")

      expect(URI.parse(current_url).path).to eq registration_path

      # Done reading introduction
      expect(page).to have_text "What do I get?"
      click_button "Let's get started!"
      expect(page).to have_content 'Woot!'

      # Filling in details
      fill_in 'enterprise_name', with: "My Awesome Enterprise"

      # Filling in address
      fill_in 'enterprise_address', with: '123 Abc Street'
      fill_in 'enterprise_city', with: 'Northcote'
      fill_in 'enterprise_zipcode', with: '3070'
      expect(page).to have_select('enterprise_country', options: ["Albania", "Australia", "France"],
                                                        selected: 'Australia')
      select 'Vic', from: 'enterprise_state'
      click_button "Continue"
      expect(page).to have_content 'Who is responsible for managing My Awesome Enterprise?'

      # Filling in Contact Details
      fill_in 'enterprise_contact', with: 'Saskia Munroe'
      expect(page).to have_field 'enterprise_email_address', with: user.email
      fill_in 'enterprise_phone', with: '12 3456 7890'
      click_button "Continue"
      expect(page).to have_content 'Last step to add My Awesome Enterprise!'

      # Choosing a type
      click_button "Create Profile"
      expect(page).to have_content("Please choose one. Are you are producer?")
      expect(page).to have_button "Create Profile", disabled: false

      click_link "producer-panel"
      expect(page).to have_selector '#producer-panel.selected'

      # Next (profile is created at this point)
      click_button "Create Profile"
      expect(page).to have_content 'Nice one!'

      # Enterprise should be created
      e = Enterprise.find_by(name: 'My Awesome Enterprise')
      expect(e.address.address1).to eq "123 Abc Street"
      expect(e.sells).to eq "unspecified"
      expect(e.is_primary_producer).to eq true
      expect(e.contact.id).to eq e.owner_id
      expect(e.contact_name).to eq "Saskia Munroe"

      # Filling in about
      fill_in 'enterprise_description', with: 'Short description'
      fill_in 'enterprise_long_desc', with: 'Long description'
      fill_in 'enterprise_abn', with: '12345'
      fill_in 'enterprise_acn', with: '54321'
      choose 'Yes' # enterprise_charges_sales_tax
      click_button "Continue"
      expect(page).to have_content 'Step 1. Select Logo Image'

      # Enterprise should be updated
      e.reload
      expect(e.description).to eq "Short description"
      expect(e.long_description).to eq "Long description"
      expect(e.abn).to eq '12345'
      expect(e.acn).to eq '54321'
      expect(e.charges_sales_tax).to be true

      # Images
      # Upload logo image
      attach_file "image-select", Rails.root.join("spec/fixtures/files/logo.png"), visible: false
      expect(page).to have_no_css('#image-placeholder .loading')
      expect(page.find('#image-placeholder img')['src']).to_not be_empty

      # Move from logo page
      click_button "Continue"
      expect(page).to have_content 'Step 3. Select Promo Image'

      # Upload promo image
      attach_file "image-select", Rails.root.join("spec/fixtures/files/promo.png"), visible: false
      expect(page).to have_no_css('#image-placeholder .loading')
      expect(page.find('#image-placeholder img')['src']).to_not be_empty

      # Move from promo page
      click_button "Continue"
      expect(page).to have_content 'How can people find My Awesome Enterprise online?'

      # Filling in social
      fill_in 'enterprise_website', with: 'www.shop.com'
      fill_in 'enterprise_facebook', with: 'FaCeBoOk'
      fill_in 'enterprise_linkedin', with: 'LiNkEdIn'
      fill_in 'enterprise_twitter', with: 'https://www.twitter.com/@TwItTeR'
      fill_in 'enterprise_instagram', with: 'www.instagram.com/InStAgRaM'
      click_button "Continue"
      expect(page).to have_content 'Finished!'

      # Done
      e.reload
      expect(e.website).to eq "www.shop.com"
      expect(e.facebook).to eq "FaCeBoOk"
      expect(e.linkedin).to eq "LiNkEdIn"
      expect(e.twitter).to eq "TwItTeR"
      expect(e.instagram).to eq "instagram"

      click_link "Go to Enterprise Dashboard"
      expect(page).to have_content "CHOOSE YOUR PACKAGE"

      page.find('.full_hub h3').click
      click_button "Select and Continue"
      expect(page).to have_content "Your profile live"
    end

    context "when the user has no more remaining enterprises" do
      before do
        user.update(enterprise_limit: 0)
      end

      it "displays the limit reached page" do
        visit registration_path

        expect(page).to have_selector "dd", text: "Login"
        switch_to_login_tab

        # Enter Login details
        fill_in "Email", with: user.email
        fill_in "Password", with: user.password
        click_button 'Login'
        expect(page).to have_content 'Oh no!'
      end
    end
  end

  describe "Terms of Service agreement" do
    let!(:user2) { create(:user) }

    before do
      login_as user2
    end

    context "if accepting Terms of Service is not required" do
      before { Spree::Config.enterprises_require_tos = false }

      it "allows registration as normal" do
        visit registration_path

        click_button "Let's get started!"
        expect(find("div#progress-bar")).to be_visible
      end
    end

    context "if accepting Terms of Service is required" do
      before { Spree::Config.enterprises_require_tos = true }

      it "does not allow registration unless checkbox is checked" do
        visit registration_path

        expect(page).to have_content "Terms of Service"
        expect(page).to have_selector "input.button.primary[disabled]"

        check "accept_terms"
        expect(page).to have_no_selector "input.button.primary[disabled]"

        click_button "Let's get started!"
        expect(find("div#progress-bar")).to be_visible
      end
    end
  end

  def switch_to_login_tab
    # Link appears to be unresponsive for a while, so keep clicking it until it works
    using_wait_time 0.5 do
      10.times do
        find("a", text: "Login").click
        break if page.has_selector? "dd.active", text: "Login"
      end
    end
  end
end
