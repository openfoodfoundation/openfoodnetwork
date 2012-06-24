require 'spec_helper'

describe Spree::HomeController do
  it "loads products" do
    product = create(:product)
    spree_get :index
    assigns(:products).should == [product]
    assigns(:products_local).should be_nil
    assigns(:products_remote).should be_nil
  end

  it "splits products by local/remote distributor when distributor is selected" do
    # Given two distributors with a product under each
    d1 = create(:distributor)
    d2 = create(:distributor)
    p1 = create(:product, :distributors => [d1])
    p2 = create(:product, :distributors => [d2])

    # And the first distributor is selected
    controller.stub(:current_distributor).and_return(d1)

    # When I fetch the home page, the products should be split by local/remote distributor
    spree_get :index
    assigns(:products).should be_nil
    assigns(:products_local).should == [p1]
    assigns(:products_remote).should == [p2]
  end
end
