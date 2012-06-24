require 'spec_helper'
require 'spree/core/current_order'

describe Spree::DistributorsController do
  include Spree::Core::CurrentOrder

  before do
    stub!(:before_save_new_order)
    stub!(:after_save_new_order)
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
end
