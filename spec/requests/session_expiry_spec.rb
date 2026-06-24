# frozen_string_literal: true

RSpec.describe "Session expiry" do
  it "is configured to expire sessions after one month" do
    expect(Rails.application.config.session_options[:expire_after]).to eq(1.month)
  end

  describe "an authenticated session" do
    let(:user) { create(:admin_user) }

    it "expires after one month of inactivity" do
      sign_in user
      get "/admin/orders"
      expect(response).not_to redirect_to(%r|#/login$|)

      travel_to(1.month.from_now + 1.second) do
        # Simulate the daily trim_sessions job removing expired sessions
        ActiveRecord::SessionStore::Session.where(updated_at: ...30.days.ago).delete_all

        get "/admin/orders"
        expect(response).to redirect_to(%r|#/login$|)
      end
    end
  end
end
