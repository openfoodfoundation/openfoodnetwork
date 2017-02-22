require 'spec_helper'
require 'spree/api/testing_support/helpers'

describe UserRegistrationsController, type: :controller do

  before do
    @request.env["devise.mapping"] = Devise.mappings[:spree_user]
  end

  describe "via ajax" do
    render_views
    it "returns errors when registration fails" do
      xhr :post, :create, spree_user: {}, :use_route => :spree
      response.status.should == 401
      json = JSON.parse(response.body)
      json.should == {"email" => ["can't be blank"], "password" => ["can't be blank"]}
    end

    it "returns 200 when registration succeeds" do
      xhr :post, :create, spree_user: {email: "test@test.com", password: "testy123", password_confirmation: "testy123"}, :use_route => :spree
      response.status.should == 200
      json = JSON.parse(response.body)
      json.should == {"email" => "test@test.com"}
      controller.spree_current_user.email.should == "test@test.com"
    end
  end

  context "when registration fails" do
    it "renders new" do
      spree_post :create, spree_user: {}
      response.status.should == 200
      response.should render_template "spree/user_registrations/new"
    end
  end

  context "when registration succeeds" do
    context "when referer is not '/checkout'" do
      it "redirects to root" do
        spree_post :create, spree_user: {email: "test@test.com", password: "testy123", password_confirmation: "testy123"}, :use_route => :spree
        response.should redirect_to root_path
        assigns[:user].email.should == "test@test.com"
      end
    end

    context "when referer is '/checkout'" do
      before { @request.env['HTTP_REFERER'] = 'http://test.com/checkout' }

      it "redirects to checkout" do
        spree_post :create, spree_user: {email: "test@test.com", password: "testy123", password_confirmation: "testy123"}, :use_route => :spree
        response.should redirect_to checkout_path
        assigns[:user].email.should == "test@test.com"
      end
    end
  end
end
