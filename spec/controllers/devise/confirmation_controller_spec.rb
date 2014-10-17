require 'spec_helper'

describe Devise::ConfirmationsController do
  context "after confirmation" do
    before do
      e = create(:enterprise, confirmed_at: nil)
      @request.env["devise.mapping"] = Devise.mappings[:enterprise]
      spree_get :show, confirmation_token: e.confirmation_token
    end

    it "should redirect to admin root" do
      expect(response).to redirect_to spree.admin_path
    end
  end
end