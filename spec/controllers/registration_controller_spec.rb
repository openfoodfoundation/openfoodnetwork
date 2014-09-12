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
end
