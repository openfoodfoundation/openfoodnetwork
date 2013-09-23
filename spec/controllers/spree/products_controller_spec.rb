require 'spec_helper'

describe Spree::ProductsController do
  context "when a distributor has not been chosen" do
    it "redirects #index to distributor selection" do
      spree_get :index
      response.should redirect_to spree.root_path
    end
  end
end
