require 'spec_helper'

feature "Registration", js: true do
  include AuthenticationWorkflow
  include WebHelper

  describe "Registering a Profile" do
    let(:user) { create(:user, password: "password", password_confirmation: "password") }

    before do
      Spree::Config.enterprises_require_tos = false

      albania = Spree::Country.create!({ name: "Albania", iso3: "ALB", iso: "AL", iso_name: "ALBANIA", numcode: "8" }, without_protection: true)
      Spree::State.create!({ name: "Berat", abbr: "BRA", country: albania }, without_protection: true)
      Spree::Country.create!({ name: "Chad", iso3: "TCD", iso: "TD", iso_name: "CHAD", numcode: "148" }, without_protection: true)
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
      click_login_and_ensure_content "Hi there!"

      expect(URI.parse(current_url).path).to eq registration_path

      # Done reading introduction
      page.has_content?
      perform_and_ensure(:click_button, "Let's get started!", lambda { page.has_content? 'Woot!' })

      # Filling in details
      fill_in 'enterprise_name', with: "My Awesome Enterprise"

      # Filling in address
      fill_in 'enterprise_address', with: '123 Abc Street'
      fill_in 'enterprise_city', with: 'Northcote'
      fill_in 'enterprise_zipcode', with: '3070'
      expect(page).to have_select('enterprise_country', options: %w(Albania Australia), selected: 'Australia')
      select 'VIC', from: 'enterprise_state'
      perform_and_ensure(:click_button, "Continue", lambda { page.has_content? 'Who is responsible for managing My Awesome Enterprise?' })


      # Filling in Contact Details
      fill_in 'enterprise_contact', with: 'Saskia Munroe'
      page.should have_field 'enterprise_email_address', with: user.email
      fill_in 'enterprise_phone', with: '12 3456 7890'
      perform_and_ensure(:click_button, "Continue", lambda { page.has_content? 'Last step to add My Awesome Enterprise!' })

      # Choosing a type
      perform_and_ensure(:click_link, 'producer-panel', lambda { page.has_selector? '#producer-panel.selected' } )
      perform_and_ensure(:click_button, "Create Profile", lambda { page.has_content? 'Nice one!' })

      # Enterprise should be created
      e = Enterprise.find_by_name('My Awesome Enterprise')
      expect(e.address.address1).to eq "123 Abc Street"
      expect(e.sells).to eq "unspecified"
      expect(e.is_primary_producer).to eq true
      expect(e.contact).to eq "Saskia Munroe"

      # Filling in about
      fill_in 'enterprise_description', with: 'Short description'
      fill_in 'enterprise_long_desc', with: 'Long description'
      fill_in 'enterprise_abn', with: '12345'
      fill_in 'enterprise_acn', with: '54321'
      choose 'Yes' # enterprise_charges_sales_tax
      perform_and_ensure(:click_button, "Continue", lambda { page.has_content? 'Step 1. Select Logo Image' })

      # Enterprise should be updated
      e.reload
      expect(e.description).to eq "Short description"
      expect(e.long_description).to eq "Long description"
      expect(e.abn).to eq '12345'
      expect(e.acn).to eq '54321'
      expect(e.charges_sales_tax).to be true

      # Images
      # Move from logo page
      perform_and_ensure(:click_button, "Continue", lambda { page.has_content? 'Step 3. Select Promo Image' })

      # Move from promo page
      perform_and_ensure(:click_button, "Continue", lambda { page.has_content? 'How can people find My Awesome Enterprise online?' })

      # Filling in social
      fill_in 'enterprise_website', with: 'www.shop.com'
      fill_in 'enterprise_facebook', with: 'FaCeBoOk'
      fill_in 'enterprise_linkedin', with: 'LiNkEdIn'
      fill_in 'enterprise_twitter', with: '@TwItTeR'
      fill_in 'enterprise_instagram', with: '@InStAgRaM'
      perform_and_ensure(:click_button, "Continue", lambda { page.has_content? 'Finished!' })

      # Done
      expect(page).to have_content "We've sent a confirmation email to #{user.email} if it hasn't been activated before."
      e.reload
      expect(e.website).to eq "www.shop.com"
      expect(e.facebook).to eq "FaCeBoOk"
      expect(e.linkedin).to eq "LiNkEdIn"
      expect(e.twitter).to eq "@TwItTeR"
      expect(e.instagram).to eq "@InStAgRaM"
    end

    context "when the user has no more remaining enterprises" do
      before do
        user.update_attributes(enterprise_limit: 0)
      end

      it "displays the limit reached page" do
        visit registration_path

        expect(page).to have_selector "dd", text: "Login"
        switch_to_login_tab

        # Enter Login details
        fill_in "Email", with: user.email
        fill_in "Password", with: user.password
        click_login_and_ensure_content I18n.t('limit_reached_headline')
      end
    end
  end

  describe "Terms of Service agreement" do
    let!(:user2) { create(:user) }

    before do
      quick_login_as user2
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

        perform_and_ensure(:check, "accept_terms", lambda { page.has_no_selector? "input.button.primary[disabled]" })

        click_button "Let's get started!"
        expect(find("div#progress-bar")).to be_visible
      end
    end
  end

  def switch_to_login_tab
    # Link appears to be unresponsive for a while, so keep clicking it until it works
    using_wait_time 0.5 do
      10.times do
        find("a", text: "Login").click()
        break if page.has_selector? "dd.active", text: "Login"
      end
    end
  end

  def click_login_and_ensure_content(content)
    # Buttons appear to be unresponsive for a while, so keep clicking them until content appears
    using_wait_time 1 do
      3.times do
        click_button "Login"
        break if page.has_selector? "div#loading", text: "Hold on a moment, we're logging you in"
      end
    end
    expect(page).to have_content content
  end
end
