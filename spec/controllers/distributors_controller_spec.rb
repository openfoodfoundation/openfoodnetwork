require 'spec_helper'
require 'spree/core/current_order'

describe Spree::DistributorsController do
  include Spree::Core::CurrentOrder

  before :each do
    stub!(:before_save_new_order)
    stub!(:after_save_new_order)

    create(:itemwise_shipping_method)
  end


  it "selects distributors" do
    d = create(:distributor)

    spree_get :select, :id => d.id
    response.should be_redirect

    order = current_order(false)
    order.distributor.should == d
  end

  it "deselects distributors" do
    d = create(:distributor)
    order = current_order(true)
    order.distributor = d
    order.save!

    spree_get :deselect
    response.should be_redirect

    order.reload
    order.distributor.should be_nil
  end

  context "when a product has been added to the cart" do
    it "does not allow selecting another distributor" do
      # Given some distributors and an order with a product
      d1 = create(:distributor)
      d2 = create(:distributor)
      p = create(:product, :distributors => [d1])
      o = current_order(true)

      o.distributor = d1
      o.save!
      o.add_variant(p.master, 1)

      # When I attempt to select a distributor
      spree_get :select, :id => d2.id

      # Then my distributor should remain unchanged
      o.reload
      o.distributor.should == d1
    end

    it "does not allow deselecting distributors" do
      # Given a distributor and an order with a product
      d = create(:distributor)
      p = create(:product, :distributors => [d])
      o = current_order(true)
      o.distributor = d
      o.save!
      o.add_variant(p.master, 1)

      # When I attempt to deselect the distributor
      spree_get :deselect

      # Then my distributor should remain unchanged
      o.reload
      o.distributor.should == d
    end
  end
end
