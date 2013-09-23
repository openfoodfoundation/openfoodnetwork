require 'spec_helper'

describe Spree::TaxonsController do
  context "when a distributor has not been chosen" do
    it "redirects #show to distributor selection" do
      taxon = create(:taxon)
      spree_get :show, {id: taxon.permalink}
      response.should redirect_to spree.root_path
    end
  end
end
