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
    d1 = create(:distributor_enterprise)
    d2 = create(:distributor_enterprise)
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
    it "loads the incomplete order when there is no current order" do
      incomplete_order = double(:order, id: 1, distributor: 2, order_cycle: 3)
      current_order = nil

      user = double(:user, last_incomplete_spree_order: incomplete_order)
      controller.stub(:try_spree_current_user).and_return(user)
      controller.stub(:current_order).and_return(current_order)

      incomplete_order.should_receive(:destroy).never
      incomplete_order.should_receive(:merge!).never

      session[:order_id] = nil
      spree_get :index
      session[:order_id].should == incomplete_order.id
    end

    it "destroys the incomplete order when there is a current order" do
      oc = double(:order_cycle, expired?: false)
      incomplete_order = double(:order, distributor: 1, order_cycle: oc)
      current_order = double(:order, distributor: 1, order_cycle: oc)

      user = double(:user, last_incomplete_spree_order: incomplete_order)
      controller.stub(:try_spree_current_user).and_return(user)
      controller.stub(:current_order).and_return(current_order)

      incomplete_order.should_receive(:destroy)
      incomplete_order.should_receive(:merge!).never
      current_order.should_receive(:merge!).never

      session[:order_id] = 123

      spree_get :index
    end
  end

  context "StoreController: handling order cycles expiring mid-order" do
    it "clears the order and displays an expiry message" do
      oc = double(:order_cycle, id: 123, expired?: true)
      controller.stub(:current_order_cycle) { oc }

      order = double(:order)
      order.should_receive(:empty!)
      order.should_receive(:set_order_cycle!).with(nil)
      controller.stub(:current_order) { order }

      spree_get :index
      session[:expired_order_cycle_id].should == 123
      response.should redirect_to spree.order_cycle_expired_orders_path
    end
  end
end
