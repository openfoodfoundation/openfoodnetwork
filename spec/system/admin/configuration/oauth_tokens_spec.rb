# frozen_string_literal: true

require 'system_helper'

RSpec.describe "OAuth tokens", feature: :oauth_provider do
  include AuthenticationHelper

  let(:user) { create(:user, email: "farmer@example.com") }
  let(:application) { create(:oauth_application, name: "Delivery planner") }
  let!(:token) { Doorkeeper::AccessToken.create!(application:, resource_owner_id: user.id) }

  before do
    login_as_admin
    visit spree.admin_dashboard_path
    click_link "Configuration"
    click_link "OAuth tokens"
  end

  it "revokes a token" do
    within "#oauth_token_#{token.id}" do
      expect(page).to have_content "farmer@example.com"
      accept_confirm { click_link "Revoke" }
    end

    expect(page).to have_content "The token has been revoked."
    expect(page).not_to have_selector "#oauth_token_#{token.id}"
    expect(token.reload).to be_revoked
  end
end
