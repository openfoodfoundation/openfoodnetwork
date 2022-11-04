# frozen_string_literal: false

require 'spec_helper'
require 'open_food_network/order_cycle_permissions'

describe WebhookEndpointsController, type: :controller do
  let(:user) { create(:admin_user) }

  before { allow(controller).to receive(:spree_current_user) { user } }

  describe "#create" do
    it "creates a webhook_endpoint" do
      expect {
        spree_post :create, { url: "https://url" }
      }.to change {
        user.webhook_endpoints.count
      }.by(1)

      expect(flash[:success]).to be_present
      expect(flash[:error]).to be_blank
      expect(user.webhook_endpoints.first.url).to eq "https://url"
    end

    it "shows error if parameters not specified" do
      expect {
        spree_post :create, { url: "" }
      }.to_not change {
        user.webhook_endpoints.count
      }

      expect(flash[:success]).to be_blank
      expect(flash[:error]).to be_present
    end

    it "redirects back to referrer" do
      spree_post :create, { url: "https://url" }

      expect(response).to redirect_to "/account#/developer_settings"
    end
  end

  describe "#destroy" do
    let!(:webhook_endpoint) { user.webhook_endpoints.create(url: "https://url") }

    it "destroys a webhook_endpoint" do
      webhook_endpoint2 = user.webhook_endpoints.create!(url: "https://url2")

      expect {
        spree_delete :destroy, { id: webhook_endpoint.id }
      }.to change {
        user.webhook_endpoints.count
      }.by(-1)

      expect(flash[:success]).to be_present
      expect(flash[:error]).to be_blank

      expect{ webhook_endpoint.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(webhook_endpoint2.reload).to be_present
    end

    it "redirects back to developer settings tab" do
      spree_delete :destroy, id: webhook_endpoint.id

      expect(response).to redirect_to "/account#/developer_settings"
    end
  end
end
