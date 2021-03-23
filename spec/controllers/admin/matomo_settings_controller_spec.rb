# frozen_string_literal: true

require 'spec_helper'

describe Admin::MatomoSettingsController, type: :controller do
  describe "#update" do
    let(:params) {
      {
        preferences: {
          matomo_url: "test url",
          matomo_site_id: "42",
          matomo_tag_manager_url: "test manager url",
        }
      }
    }

    before do
      allow(controller).to receive(:spree_current_user) { create(:admin_user) }
    end

    it "changes Matomo settings" do
      expect {
        post :update, params: params
      }.to change {
        [
          Spree::Config[:matomo_url],
          Spree::Config[:matomo_site_id],
          Spree::Config[:matomo_tag_manager_url],
        ]
      }.to(
        [
          "test url",
          "42",
          "test manager url",
        ]
      )
    end
  end
end
