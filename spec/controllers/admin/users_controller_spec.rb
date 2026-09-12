# frozen_string_literal: true

RSpec.describe Admin::UsersController do
  render_views

  describe "#accept_terms_of_service" do
    let(:user) { create(:user, terms_of_service_accepted_at: nil) }

    before do
      allow(controller).to receive(:spree_current_user) { user }
    end

    it "updates terms_of_service_accepted_at" do
      expect {
        patch :accept_terms_of_service, format: :turbo_stream
        user.reload
      }.to change { user.terms_of_service_accepted_at }
    end

    it "removes the banner via turbo stream" do
      patch :accept_terms_of_service, format: :turbo_stream

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include('turbo-stream action="remove" target="banner-container"')
    end
  end
end
