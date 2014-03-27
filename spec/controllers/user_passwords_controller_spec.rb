require 'spec_helper'
require 'spree/api/testing_support/helpers'

describe UserPasswordsController do

  before do
    @request.env["devise.mapping"] = Devise.mappings[:spree_user]
    ActionMailer::Base.default_url_options[:host] = "test.host"
  end

  it "returns errors when no data received" do
    spree_post :create, spree_user: {}
    response.should be_success
    response.should render_template "spree/user_passwords/new"
  end

  it "redirects to login when data is valid" do
    user = create(:user)
    spree_post :create, spree_user: { email: user.email}
    response.should be_redirect
  end

end

