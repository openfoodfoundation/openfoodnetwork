require 'spec_helper'

feature %q{
    As a consumer
    I want to choose a distributor when adding products to my cart
    So that I can avoid making an order from many different distributors
} do
  include AuthenticationWorkflow
  include WebHelper

  context "adding the first product to the cart" do
    it "requires the user choose a distributor" do
      # Tested in orders_controller_spec.rb
    end

    it "sets the order's distributor"
    it "sets the user's distributor when adding a product at a remote distributor"
  end

  it "does not allow the user to change distributor after a product has been added to the cart"

  context "adding a subsequent product to the cart" do
    it "does not allow the user to choose a distributor" do
      # Instead, they see "Your distributor for this order is XYZ"
      pending
    end

    it "does not allow the user to add a product from another distributor" do
      # No add to cart button
      # They see "Please complete your order at XYZ before shopping with another distributor."
      pending
    end
  end
end
