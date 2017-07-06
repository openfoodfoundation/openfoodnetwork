require 'spec_helper'
require 'spree/api/testing_support/helpers'

describe UserPasswordsController, type: :controller do
  let(:user) { create(:user) }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:spree_user]
  end

  describe "create" do
    it "returns errors" do
      spree_post :create, spree_user: {}
      response.should be_success
      response.should render_template "spree/user_passwords/new"
    end

    it "redirects to login when data is valid" do
      spree_post :create, spree_user: { email: user.email}
      response.should be_redirect
    end
  end

  describe "edit" do
    context "when given a redirect" do
      it "stores the redirect path in 'spree_user_return_to'" do
        spree_post :edit, reset_password_token: "token", return_to: "/return_path"
        expect(session["spree_user_return_to"]).to eq "/return_path"
      end
    end
  end

  it "renders Darkswarm" do
    clear_jobs
    user.send_reset_password_instructions
    flush_jobs # Send the reset password instructions
    user.reload
    spree_get :edit, reset_password_token: user.reset_password_token
    response.should render_template "user_passwords/edit"
  end

  describe "via ajax" do
    it "returns errors" do
      xhr :post, :create, spree_user: {}, use_route: :spree
      json = JSON.parse(response.body)
      response.status.should == 401
      json.should == {"email"=>["can't be blank"]}
    end
  end
end
