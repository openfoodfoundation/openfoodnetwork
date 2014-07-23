require 'spec_helper'

module Spree
  describe PaypalController do
    it "should redirect back to checkout after cancel" do
      spree_get :cancel
      response.should redirect_to checkout_path
    end
  end
end
