require 'spec_helper'

describe RegistrationController do
  it "redirects to authentication page when user not logged in" do
    get :index
    response.should redirect_to registration_auth_path(anchor: "signup?after_login=/register")
  end
end
