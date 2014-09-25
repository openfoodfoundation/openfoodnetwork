require 'spec_helper'

describe RegistrationController do
  describe "redirecting when user not logged in" do
    it "index" do
      get :index
      response.should redirect_to registration_auth_path(anchor: "signup?after_login=/register")
    end

    it "store" do
      get :store
      response.should redirect_to registration_auth_path(anchor: "signup?after_login=/register/store")
    end
  end

  describe "loading data when user is logged in" do
    let!(:user) { double(:user) }

    before do
      controller.stub spree_current_user: user
      user.stub spree_api_key: '12345'
      user.stub last_incomplete_spree_order: nil
    end

    describe "index" do
      it "loads the spree api key" do
        get :index
        expect(assigns(:spree_api_key)).to eq '12345'
      end
    end

    describe "store" do
      it "loads the spree api key" do
        get :store
        expect(assigns(:spree_api_key)).to eq '12345'
      end
    end
  end
end
