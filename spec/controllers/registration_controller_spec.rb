# frozen_string_literal: true

require 'spec_helper'

describe RegistrationController, type: :controller do
  describe "redirecting when user not logged in" do
    it "index" do
      get :index
      expect(response)
        .to redirect_to registration_auth_path(anchor: "/signup", after_login: "/register")
    end
  end

  describe "redirecting when user has reached enterprise ownership limit" do
    let!(:user) { create(:user, enterprise_limit: 1 ) }
    let!(:enterprise) { create(:distributor_enterprise, owner: user) }

    before do
      allow(controller).to receive_messages spree_current_user: user
    end

    it "index" do
      get :index
      expect(response).to render_template :limit_reached
    end
  end

  describe "loading data when user is logged in" do
    let!(:user) { create(:user) }

    before do
      allow(controller).to receive_messages spree_current_user: user
    end

    describe "index" do
      it "loads the spree api key" do
        get :index
        expect(assigns(:spree_api_key)).to eq user.spree_api_key
      end
    end
  end
end
