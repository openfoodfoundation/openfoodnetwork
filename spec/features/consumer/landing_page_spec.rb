require 'spec_helper'

feature %q{
    As a consumer
    I want to see the landing page
    So I can login or search
} do

  background do
    LandingPageImage.create photo: File.open(File.join(Rails.root, "lib", "seed_data", "tomatoes.jpg"))
  end

  scenario "viewing the landing page" do
    visit new_landing_page_path

    page.should have_selector "#postcode"
    page.should have_selector 'a', :text => "Login"
    page.should have_selector 'a', :text => "Sign Up"
  end
end