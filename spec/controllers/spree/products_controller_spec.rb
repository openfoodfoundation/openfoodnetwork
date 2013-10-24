require 'spec_helper'

describe Spree::ProductsController do
  context "when a distributor has not been chosen" do
    it "redirects #index to distributor selection" do
      spree_get :index
      response.should redirect_to spree.root_path
    end
  end

  context "when a distributor has been chosen" do
    it "redirects #index to the distributor page" do
      d = create(:distributor_enterprise)
      controller.stub(:current_distributor) { d }

      spree_get :index
      response.should redirect_to enterprise_path(d)
    end
  end
end
