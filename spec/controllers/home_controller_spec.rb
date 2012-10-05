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

  context "BaseController: merging incomplete orders" do
    it "does not attempt to merge incomplete and current orders when they have differing distributors" do
      incomplete_order = double(:order, distributor: 1)
      current_order = double(:order, distributor: 2)

      user = double(:user, last_incomplete_order: incomplete_order)
      controller.stub(:current_user).and_return(user)
      controller.stub(:current_order).and_return(current_order)

      incomplete_order.should_receive(:destroy)
      incomplete_order.should_receive(:merge!).never
      current_order.should_receive(:merge!).never

      session[:order_id] = 123

      spree_get :index
    end
  end
end
