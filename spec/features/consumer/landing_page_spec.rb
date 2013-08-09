require 'spec_helper'

feature %q{
    As a consumer
    I want to see the landing page
    So I can login or search
}, js: true do

  background do
    LandingPageImage.create photo: File.open(File.join(Rails.root, "lib", "seed_data", "tomatoes.jpg"))
    visit new_landing_page_path
  end

  scenario "viewing the landing page" do
    page.should have_selector "#postcode"
    page.should have_selector 'a', :text => "Login"
    page.should have_selector 'a', :text => "Sign Up"
  end

  describe "login" do
    before(:each) do
      Spree::User.create(:email => "spree123@example.com", :password => "spree123")
      find(:xpath, '//a[contains(text(), "Login")]').click
    end

    scenario "with valid credentials" do
      fill_in 'spree_user_email', :with => 'spree123@example.com'
      fill_in 'spree_user_password', :with => 'spree123'
      find(:xpath, '//input[contains(@value, "Login")][contains(@type, "submit")]').click
      sleep 3
      page.should_not have_content("Invalid email or password")
      page.should have_content("Sign Out")
    end

    scenario "with invalid credentials" do
      fill_in 'spree_user_email', :with => 'spree123@example.com.WRONG'
      fill_in 'spree_user_password', :with => 'spree123_WRONG'
      find(:xpath, '//input[contains(@value, "Login")][contains(@type, "submit")]').click
      sleep 3
      page.should have_content("Invalid email or password")
      page.should_not have_content("Sign Out")
    end
  end
end