require 'spec_helper'

describe Spree::OrdersController do
  context "adding the first product to the cart" do
    it "does nothing if the user does not specify a distributor" do
      create(:distributor)
      p = create(:product)

      expect do
        spree_put :populate, :variants => {p.id => 1}
      end.to change(Spree::LineItem, :count).by(0)
    end
  end
end
