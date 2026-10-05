# frozen_string_literal: true

require 'system_helper'

RSpec.describe "Connected Apps" do
  include AuthenticationHelper

  let(:user) { create(:user) }
  let(:application) { create(:oauth_application, name: "Delivery planner") }
  let!(:token) { Doorkeeper::AccessToken.create!(application:, resource_owner_id: user.id) }

  before do
    login_as user
    visit "/account"
    find("a", text: /Connected Apps/i).click
  end

  it "lets the user revoke an application" do
    within "#connected_app_#{application.id}" do
      accept_confirm { click_button "Revoke" }
    end

    expect(page).to have_content "Delivery planner can no longer access your account."
    expect(page).to have_content "You haven't connected any application yet."
    expect(token.reload).to be_revoked
  end
end
