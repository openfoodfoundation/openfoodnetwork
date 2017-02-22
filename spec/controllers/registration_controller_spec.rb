require 'spec_helper'

describe RegistrationController, type: :controller do
  include AuthenticationWorkflow
  describe "redirecting when user not logged in" do
    it "index" do
      get :index
      response.should redirect_to registration_auth_path(anchor: "signup?after_login=/register")
    end
  end

  describe "redirecting when user has reached enterprise ownership limit" do
    let!(:user) { create_enterprise_user( enterprise_limit: 1 ) }
    let!(:enterprise) { create(:distributor_enterprise, owner: user) }

    before do
      controller.stub spree_current_user: user
    end

    it "index" do
      get :index
      response.should render_template :limit_reached
    end
  end

  describe "loading data when user is logged in" do
    let!(:user) { create_enterprise_user }

    before do
      controller.stub spree_current_user: user
    end

    describe "index" do
      it "loads the spree api key" do
        get :index
        expect(assigns(:spree_api_key)).to eq user.spree_api_key
      end
    end
  end
end
