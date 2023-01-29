# frozen_string_literal: true

require 'spec_helper'

describe Spree::ApiKeysController, type: :controller, performance: true do
  routes { Spree::Core::Engine.routes }

  include AuthenticationHelper
  include ControllerRequestsHelper

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:redirect_path) { "#{spree.account_path}#/developer_settings" }

  before do
    allow(controller).to receive(:spree_current_user) { user }
  end

  describe "create" do
    it "creates a new api key" do
      expect { spree_post :create }.to change { user.reload.spree_api_key }
      expect(user.spree_api_key).to be_present
    end

    it "denies creating a new api key for other user" do
      expect {
        spree_post :create, id: other_user.id
        other_user.reload
      }.to_not change {
        other_user.spree_api_key
      }
    end

    it "redirects to the api keys tab on account page " do
      spree_post :create
      expect(response).to redirect_to redirect_path
    end
  end

  describe "destroy" do
    before do
      user.generate_api_key
      user.save
    end

    it "clears the api key" do
      expect { spree_delete :destroy, id: user.id }.to change { user.reload.spree_api_key }.to(nil)
    end

    it "redirects to the api keys tab on account page " do
      spree_delete :destroy, id: user.id
      expect(response).to redirect_to redirect_path
    end
  end
end
