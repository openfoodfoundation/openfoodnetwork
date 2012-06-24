require 'spec_helper'
require 'spree/core/current_order'

describe Spree::OrdersController do
  include Spree::Core::CurrentOrder

  context "adding the first product to the cart" do
    it "does not add the product if the user does not specify a distributor" do
      create(:distributor)
      p = create(:product)

      expect do
        spree_put :populate, :variants => {p.id => 1}
      end.to change(Spree::LineItem, :count).by(0)
    end

    it "does not add the product if the user specifies a distributor that the product is not available at" do
      distributor_product = create(:distributor)
      distributor_no_product = create(:distributor)
      p = create(:product, :distributors => [distributor_product])

      expect do
        spree_put :populate, :variants => {p.id => 1}, :distributor_id => distributor_no_product.id
      end.to change(Spree::LineItem, :count).by(0)
    end

    it "sets the order's distributor" do
      # Given a product in a distributor
      d = create(:distributor)
      p = create(:product, :distributors => [d])

      # When we add the product to our cart
      spree_put :populate, :variants => {p.id => 1}, :distributor_id => d.id

      # Then our order should have its distributor set to the chosen distributor
      current_order(false).distributor.should == d
    end

  end
end
