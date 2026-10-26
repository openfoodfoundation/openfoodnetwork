# frozen_string_literal: true

require 'system_helper'

RSpec.describe "OAuth applications", feature: :oauth_provider do
  include AuthenticationHelper

  before do
    login_as_admin
    visit spree.admin_dashboard_path
    click_link "Configuration"
    click_link "OAuth applications"
  end

  it "registers an application and shows its credentials" do
    click_link "New OAuth application"
    fill_in "Name", with: "Stock sync"
    fill_in "Redirect URI", with: "https://sync.example.com/callback"
    click_button "Create"

    application = Doorkeeper::Application.find_by!(name: "Stock sync")
    expect(page).to have_content "Stock sync has been successfully created!"
    expect(page).to have_field "Client ID", with: application.uid
    expect(page).to have_field "Client secret", with: application.secret
  end
end
