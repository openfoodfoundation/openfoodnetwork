# frozen_string_literal: true

require "system_helper"

RSpec.describe "Stripe account disconnect" do
  include AuthenticationHelper
  include WebHelper

  let(:user) { create(:user, enterprise_limit: 1) }
  let(:enterprise) { create(:distributor_enterprise) }
  let!(:stripe_account) {
    create(:stripe_account, enterprise:, stripe_user_id: "abc123")
  }
  # A second account sharing the stripe_user_id makes #deauthorize_and_destroy
  # skip the Stripe API call.
  let!(:sibling_account) { create(:stripe_account, stripe_user_id: "abc123") }

  before do
    user.enterprise_roles.build(enterprise:).save!
    login_as user
  end

  it "disconnects the account and returns to the enterprise form" do
    visit edit_admin_enterprise_path(enterprise)

    within ".side_menu" do
      click_link "Payment Methods"
    end

    expect(page).to have_link "Disconnect account"
    click_link "Disconnect account"

    expect(page).to have_content "Stripe account disconnected."
    expect(page).to have_current_path edit_admin_enterprise_path(enterprise)
  end
end
