require 'spec_helper'
require 'spree/core/current_order'

describe Spree::DistributorsController do
  include Spree::Core::CurrentOrder

  it "selects distributors" do
    d = create(:distributor)

    spree_get :select, :id => d.id

    order = current_order(false)
    order.distributor.should == d
    response.should be_redirect
  end
end
