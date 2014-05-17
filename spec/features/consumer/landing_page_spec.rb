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
    page.should have_selector "#suburb_search"
  end

  # PENDING - we're not using this anymore
  pending "suburb search" do
    before(:each) do
      state_id_vic = Spree::State.where(abbr: "Vic").first.id
      Suburb.create(name: "Camberwell", postcode: 3124, latitude: -37.824818, longitude: 145.057957, state_id: state_id_vic)
    end

    it "should auto complete suburbs" do
      suburb_search_field_id = "suburb_search"
      fill_in suburb_search_field_id, :with => "Cambe"
      page.execute_script %Q{ $('##{suburb_search_field_id}').trigger("focus") }
      page.execute_script %Q{ $('##{suburb_search_field_id}').trigger("keydown") }
      sleep 1
      page.should have_content("Camberwell")
      page.should have_content("3124")
    end
  end
end
