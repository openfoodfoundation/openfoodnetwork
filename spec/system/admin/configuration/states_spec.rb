# frozen_string_literal: true

require 'system_helper'

describe "States" do
  include AuthenticationHelper
  include WebHelper

  let!(:country) { create(:country) }

  before(:each) do
    login_as_admin
    @hungary = Spree::Country.create!(name: "Hungary", iso_name: "Hungary", iso: "HU")

    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("DEFAULT_COUNTRY_CODE").and_return("HU")
  end

  # TODO: For whatever reason, rendering of the states page takes a non-trivial amount of time
  # Therefore we navigate to it, and wait until what we see is visible
  def go_to_states_page
    visit spree.admin_country_states_path(country)
    counter = 0
    until page.has_css?("#new_state_link")
      raise "Could not see new state link!" if counter >= 10

      sleep(2)
      counter += 1
    end
  end

  context "admin visiting states listing" do
    let!(:state) { Spree::State.create(name: 'Alabama', country: country) }

    it "should correctly display the states" do
      visit spree.admin_country_states_path(country)
      expect(page).to have_content(state.name)
    end
  end

  context "creating and editing states" do
    it "should allow an admin to edit existing states" do
      go_to_states_page
      select2_select country.name, from: "country"

      click_link "new_state_link"
      fill_in "state_name", with: "Calgary"
      fill_in "Abbreviation", with: "CL"
      click_button "Create"
      expect(page).to have_content("successfully created!")
      expect(page).to have_content("Calgary")
    end

    it "should allow an admin to create states for non default countries" do
      go_to_states_page
      select2_select @hungary.name, from: "country"
      # Just so the change event actually gets triggered in this spec
      # It is definitely triggered in the "real world"
      page.execute_script("$('#country').trigger('change');")

      click_link "new_state_link"
      fill_in "state_name", with: "Pest megye"
      fill_in "Abbreviation", with: "PE"
      click_button "Create"
      expect(page).to have_content("successfully created!")
      expect(page).to have_content("Pest megye")
      expect(find("#s2id_country span.select2-chosen").text).to eq("Hungary")
    end

    it "should show validation errors" do
      go_to_states_page
      select2_select country.name, from: "country"
      click_link "new_state_link"

      fill_in "state_name", with: ""
      fill_in "Abbreviation", with: ""
      click_button "Create"
      expect(page).to have_content("Name can't be blank")
    end
  end
end
