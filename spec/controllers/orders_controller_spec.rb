require 'spec_helper'
require 'spree/core/current_order'

describe Spree::OrdersController do
  include Spree::Core::CurrentOrder

  def current_user
    controller.current_user
  end


  context "adding the first product to the cart" do
    it "does not add the product if the user does not specify a distributor" do
      create(:distributor_enterprise)
      p = create(:product)

      expect do
        spree_post :populate, :variants => {p.master.id => 1}
      end.to change(Spree::LineItem, :count).by(0)
    end

    it "does not add the product if the user specifies a distributor that the product is not available at" do
      distributor_product = create(:distributor_enterprise)
      distributor_no_product = create(:distributor_enterprise)
      p = create(:product, :distributors => [distributor_product])

      expect do
        spree_post :populate, :variants => {p.master.id => 1}, :distributor_id => distributor_no_product.id
      end.to change(Spree::LineItem, :count).by(0)
    end

    it "adds the product and sets the distributor even if the order has a different distributor set" do
      distributor_product = create(:distributor_enterprise)
      distributor_no_product = create(:distributor_enterprise)
      p = create(:product, :distributors => [distributor_product])

      order = current_order(true)
      order.distributor = distributor_no_product
      order.save!

      expect do
        spree_post :populate, :variants => {p.master.id => 1}, :distributor_id => distributor_product.id
      end.to change(Spree::LineItem, :count).by(1)

      order.reload.distributor.should == distributor_product
    end

    it "sets the order's distributor" do
      # Given a product in a distributor
      d = create(:distributor_enterprise)
      p = create(:product, :distributors => [d])

      # When we add the product to our cart
      spree_post :populate, :variants => {p.master.id => 1}, :distributor_id => d.id

      # Then our order should have its distributor set to the chosen distributor
      current_order(false).distributor.should == d
    end
  end

  context "adding a subsequent product to the cart" do
    before(:each) do
      # Given a product and a distributor
      @distributor = create(:distributor_enterprise)
      @product = create(:product, :distributors => [@distributor])

      # And the product is in the cart
      spree_post :populate, :variants => {@product.master.id => 1}, :distributor_id => @distributor.id
      current_order(false).line_items.reload.map { |li| li.product }.should == [@product]
      current_order(false).distributor.reload.should == @distributor
    end

    it "does not add the product if the product is not available at the order's distributor" do
      # Given a product at another distributor
      d2 = create(:distributor_enterprise)
      p2 = create(:product, :distributors => [d2])

      # When I attempt to add the product to the cart
      spree_post :populate, :variants => {p2.master.id => 1}, :distributor_id => d2.id

      # Then the product should not be added to the cart
      current_order(false).line_items.reload.map { |li| li.product }.should == [@product]
      current_order(false).distributor.reload.should == @distributor
    end

    it "does not add the product if the product is not available at the given distributor" do
      # Given a product at another distributor
      d2 = create(:distributor_enterprise)
      p2 = create(:product, :distributors => [d2])

      # When I attempt to add the product to the cart with a fake distributor_id
      spree_post :populate, :variants => {p2.master.id => 1}, :distributor_id => @distributor.id

      # Then the product should not be added to the cart
      current_order(false).line_items.reload.map { |li| li.product }.should == [@product]
      current_order(false).distributor.reload.should == @distributor
    end

    it "does not add the product if the chosen distributor is different from the order's distributor" do
      # Given a product that's available at the chosen distributor and another distributor
      d2 = create(:distributor_enterprise)
      p2 = create(:product, :distributors => [@distributor, d2])

      # When I attempt to add the product to the cart with the alternate distributor
      spree_post :populate, :variants => {p2.master.id => 1}, :distributor_id => d2

      # Then the product should not be added to the cart
      current_order(false).line_items.reload.map { |li| li.product }.should == [@product]
      current_order(false).distributor.reload.should == @distributor
    end
  end

  context "adding a group buy product to the cart" do
    it "sets a variant attribute for the max quantity" do
      distributor_product = create(:distributor_enterprise)
      p = create(:product, :distributors => [distributor_product], :group_buy => true)

      order = current_order(true)
      order.should_receive(:set_variant_attributes).with(p.master, {'max_quantity' => '3'})
      controller.stub(:current_order).and_return(order)

      expect do
        spree_post :populate, :variants => {p.master.id => 1}, :variant_attributes => {p.master.id => {:max_quantity => 3}}, :distributor_id => distributor_product.id
      end.to change(Spree::LineItem, :count).by(1)
    end
  end
end
